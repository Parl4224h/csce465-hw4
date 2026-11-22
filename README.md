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


