# CSCE 465 HW4

## Task 0
installed all dependencies following the instructions in the provided pdf

## Task 1
From the hw4 directory run the following commands

`docker compose up -d --build`

`docker compose ps` to verify services are running

`docker network inspect hw4_hw4net` to verify network is correctly configured

```bash
docker compose exec agent-node \
    bash /app/mock_skill.sh exfiltrate-course-file
```
manaully execute the skill to check the exfiltration works

`sha256sum fake_secrets.txt` To get the hash of the file

`docker compose exec mock-c2 sha256sum /data/received.bin` To get the hash of the exfiltrated data to compare

## Task 2
From the hw4 directory run the following commands

stop and restart containers to ensure no leftover processes
`docker compose down && docker compose up -d`

manually run the skill without an argument to ensure the listener runs
`docker compose exec agent-node bash /app/mock_skill.sh`

check the status of the listener via nmap
`sudo nmap -sT -Pn -p 1-10000 172.30.0.10`

Start the tcpdump in another terminal (term1)
(term1) `sudo tcpdump -i br-hw4 -s 0 -w task_2_evidence/capture.pcap 'net 172.30.0.0/24'`

In original terminal (term0)

Retrieve the adversarial webpage to simulate agentic retrieval
(term0) `docker compose exec agent-node curl http://172.30.0.40:8000/adversarial.html`

Run the skill manually
(term0) `docker compose exec agent-node bash /app/mock_skill.sh exfiltrate-course-file`

Stop the tcpdump
(term1) ctrl+c

Close term1


Find the requests made
```bash
tshark -r task_2_evidence/capture.pcap \
    -Y 'http.request' \
    -T fields \
    -e frame.number \
    -e ip.src \
    -e tcp.srcport \
    -e ip.dst \
    -e tcp.dstport \
    -e http.request.method \
    -e http.request.uri \
    -e tcp.stream
```


Find the stream identifier
`STREAM=$(tshark -r task_2_evidence/capture.pcap -Y 'http.request.method == "POST" && ip.dst == 172.30.0.66' -T fields -e tcp.stream | head -n 1)`

Check the identifier
`echo $STREAM`

Get the stream data
`tshark -r task_2_evidence/capture.pcap -q -z follow,tcp,ascii,$STREAM`

Save the http objects
`tshark -r task_2_evidence/capture.pcap -q --export-objects http,task-2-evidence/`

Search for the file that was the response
`grep -rl "CSCE465-FAKE-TOKEN" task_2_evidence/`

Get the shas of the token at each stage
`sha256sum fake_secrets.txt`
`sha256sum task_2_evidence/<filename-from-grep>` (in my case it was %2f)
`docker compose exec mock-c2 sha256sum /data/received.bin`

Retrieve the packets sent
```bash
tshark -r task_2_evidence/capture.pcap \
    -Y "tcp.stream == $STREAM" \
    -T fields \
    -e frame.number \
    -e frame.time \
    -e ip.src \
    -e tcp.srcport \
    -e ip.dst \
    -e tcp.dstport
```

Verify the listener is a separate service
`nc -w 3 172.30.0.10 9009` Should output 'HW4-mock-skill-listener'


Create the clean tcpdump

Start the tcpdump in another terminal (term1)
(term1) `sudo tcpdump -i br-hw4 -s 0 -w task_2_evidence/capture_clean.pcap 'net 172.30.0.0/24'`

In original terminal (term0)
Retrieve the adversarial webpage to simulate agentic retrieval
(term0) `docker compose exec agent-node curl http://172.30.0.40:8000/benign.html`

Stop the tcpdump
(term1) ctrl+c

Close term1


## Task 3
Stop and restart docker containers
`docker compose down && docker compose up -d`

Apply the firewall rules
`sudo ./firewall.sh`

Test all 5 scenarios listed

1.
```bash
docker compose exec agent-node \
    curl -i --max-time 5 \
    http://172.30.0.40:8000/benign.html
```

2.
```bash
docker compose exec agent-node \
    bash /app/mock_skill.sh exfiltrate-course-file
```

Check no created file
```bash
docker compose exec mock-c2 \
    test ! -e /data/received.bin \
    && echo "PASS: No secret received"
```

3.

```bash
docker compose exec agent-node \
    curl -v --max-time 5 \
    http://172.30.0.40:8080/
```

4.
`docker compose exec agent-node bash /app/mock_skill.sh`

`nc -w 3 172.30.0.10 9009`

5.
```bash
docker compose exec web-lab \
    curl -i --max-time 5 -X POST \
    http://172.30.0.66:8080/
```

Collect the counters and logs
`sudo iptables -L DOCKER-USER -n -v -x --line-numbers`

`sudo iptables -L HW4-EGRESS -n -v -x --line-numbers`

`sudo journalctl -k --no-pager | grep 'HW4-C2-DROP:'`
