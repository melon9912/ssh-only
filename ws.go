package main

import (
	"bufio"
	"fmt"
	"io"
	"net"
	"os"
	"strings"
	"time"
)

const (
	LISTEN_ADDR = "0.0.0.0"
	DEFAULT_HOST = "127.0.0.1:143"
	PASS = "" // isi jika mau pakai password
)

var (
	LISTEN_PORT = "80"
)

const FAKE_HTTP_RESPONSE = "HTTP/1.1 101 Switching Protocols\r\n" +
	"Upgrade: websocket\r\n" +
	"Connection: Upgrade\r\n\r\n"

func main() {
	if len(os.Args) > 1 {
		LISTEN_PORT = os.Args[1]
	}

	addr := LISTEN_ADDR + ":" + LISTEN_PORT
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		fmt.Println("Listen error:", err)
		return
	}

	fmt.Println("[+] Listening on", addr)

	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}
		go handleClient(conn)
	}
}

func handleClient(client net.Conn) {
	defer client.Close()
	client.SetDeadline(time.Now().Add(10 * time.Second))

	reader := bufio.NewReader(client)

	// Read HTTP header
	var headers []string
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return
		}
		line = strings.TrimRight(line, "\r\n")
		if line == "" {
			break
		}
		headers = append(headers, line)
	}

	host := getHeader(headers, "X-Real-Host")
	pass := getHeader(headers, "X-Pass")
	split := getHeader(headers, "X-Split")

	if split != "" {
		reader.Read(make([]byte, 4096))
	}

	if host == "" {
		host = DEFAULT_HOST
	}

	if PASS != "" && pass != PASS {
		client.Write([]byte("HTTP/1.1 403 Forbidden\r\n\r\n"))
		return
	}

	if !strings.HasPrefix(host, "127.0.0.1") &&
		!strings.HasPrefix(host, "localhost") {
		client.Write([]byte("HTTP/1.1 403 Forbidden\r\n\r\n"))
		return
	}

	target, err := net.Dial("tcp", host)
	if err != nil {
		return
	}
	defer target.Close()

	// Send fake HTTP response
	client.Write([]byte(FAKE_HTTP_RESPONSE))

	client.SetDeadline(time.Time{})
	target.SetDeadline(time.Time{})

	go pipe(client, target)
	pipe(target, client)
}

func pipe(src net.Conn, dst net.Conn) {
	defer src.Close()
	defer dst.Close()
	io.Copy(dst, src)
}

func getHeader(headers []string, key string) string {
	key = strings.ToLower(key)
	for _, h := range headers {
		if strings.HasPrefix(strings.ToLower(h), key+":") {
			return strings.TrimSpace(strings.SplitN(h, ":", 2)[1])
		}
	}
	return ""
}
