

package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const (
	localAddr  = "/run/synoscgi_rr.sock"
	remoteAddr = "/run/synoscgi.sock"
)

func getCpuTemp() int {
	thermals, err := filepath.Glob("/sys/class/hwmon/hwmon*/temp*_input")
	if err != nil {
		log.Printf("Error globbing thermal zones: %v", err)
		return 0
	}

	var temps []int
	for _, zonePath := range thermals {
		labelPath := strings.Replace(zonePath, "_input", "_label", 1)
		if _, err := os.Stat(labelPath); os.IsNotExist(err) {
			continue
		}

		label, err := os.ReadFile(labelPath)
		if err != nil {
			log.Printf("Error reading label file: %v", err)
			continue
		}

		if strings.Contains(strings.ToLower(string(label)), "tctl") ||
			strings.Contains(strings.ToLower(string(label)), "tdie") ||
			strings.Contains(strings.ToLower(string(label)), "core") {
			tempData, err := os.ReadFile(zonePath)
			if err != nil {
				log.Printf("Error reading temperature file: %v", err)
				continue
			}

			temp, err := strconv.Atoi(strings.TrimSpace(string(tempData)))
			if err != nil {
				log.Printf("Error converting temperature to integer: %v", err)
				continue
			}

			temps = append(temps, temp/1000) // Convert to Celsius
		}
	}

	if len(temps) > 0 {
		sum := 0
		for _, temp := range temps {
			sum += temp
		}
		return sum / len(temps) // Return average temperature
	}

	return 0
}

func modifyInfo(data []byte) []byte {
	//
	temp := getCpuTemp()
	re := regexp.MustCompile(`"sys_temp":\d+`)
	data = re.ReplaceAll(data, []byte(fmt.Sprintf(`"sys_temp":%d`, temp)))
	//
	return data
}

func isIgnorableError(err error) bool {
	if netErr, ok := err.(net.Error); ok && !netErr.Temporary() {
		return true
	}
	return err == io.EOF
}

func handleConnection(localConn net.Conn, remoteAddr string) {
	defer localConn.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	remoteConn, err := net.DialTimeout("unix", remoteAddr, 5*time.Second)
	if err != nil {
		log.Printf("Failed to connect to remote socket: %v", err)
		return
	}
	defer remoteConn.Close()

	go proxyData(ctx, localConn, remoteConn, cancel, false)
	go proxyData(ctx, remoteConn, localConn, cancel, true)

	<-ctx.Done()
}

func proxyData(ctx context.Context, src, dst net.Conn, cancel context.CancelFunc, modify bool) {
	buf := make([]byte, 32*1024)
	var dataBuffer bytes.Buffer

	for {
		select {
		case <-ctx.Done():
			return
		default:
			n, err := src.Read(buf)
			if n > 0 {
				data := buf[:n]
				if modify && bytes.Contains(data, []byte(`"sys_temp"`)) {
					dataBuffer.Write(data)
					modifiedData := modifyInfo(dataBuffer.Bytes())
					dataBuffer.Reset()
					if _, err := dst.Write(modifiedData); err != nil {
						log.Printf("Error writing modified data to destination: %v", err)
						cancel()
						return
					}
				} else {
					if _, err := dst.Write(data); err != nil {
						log.Printf("Error writing to destination: %v", err)
						cancel()
						return
					}
				}
			}
			if err != nil {
				if !isIgnorableError(err) {
					log.Printf("Error reading from source: %v", err)
				}
				cancel()
				return
			}
		}
	}
}

func listenAndProxy(localAddr, remoteAddr string) {
	if err := os.RemoveAll(localAddr); err != nil {
		log.Fatalf("Failed to remove existing socket file: %v", err)
	}

	localListener, err := net.Listen("unix", localAddr)
	if err != nil {
		log.Fatalf("Failed to listen on local socket: %v", err)
	}
	defer os.Remove(localAddr)
	defer localListener.Close()

	if err := os.Chmod(localAddr, 0777); err != nil {
		log.Fatalf("Failed to set permissions on socket file: %v", err)
	}
	log.Printf("Listening on %s, proxying to %s\n", localAddr, remoteAddr)

	for {
		localConn, err := localListener.Accept()
		if err != nil {
			log.Printf("Failed to accept local connection: %v", err)
			continue
		}
		go handleConnection(localConn, remoteAddr)
	}
}

func main() {
	tempFlag := flag.Bool("t", false, "Read and print CPU Temperature")
	flag.Parse()

	if *tempFlag {
		if temp := getCpuTemp(); temp != 0 {
			log.Printf("%d\n", temp)
			os.Exit(0)
		} else {
			os.Exit(1)
		}
	}

	listenAndProxy(localAddr, remoteAddr)
}
