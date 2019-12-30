# MessageQueueExample

This is example code I built in Elixir for building a simple queue.

Following requirements:

1. Your application can be based on Phoenix or can be a simple Plug based web server.
2. You should have an HTTP endpoint at the path /receive-message which accepts a GET request with the query string parameters queue (string) message (string).
3. Your application should accept messages as quickly as they come in and return a 200 status code.
4. Your application should "process" the messages by printing the message text to the terminal, however for each queue, your application should only "process" one message a second, no matter how quickly the messages are submitted to the HTTP endpoint.
5. Bonus points for writing some kind of test that verifies messages are only processed one per second.

Please provide any feedback as for the most part I have just used Elixir Phoenix and haven't done as much with GenServers.

# Better solution

In this code I wrote code to pass queues to another node in the cluster but if this needed to run in production and you can't lose messages you would need to store the messages in a DB and then marked them processed or delete after they are processed. If you didn't do that and all nodes went down you could lose messages. 

Also my node switching code would not guarantee order if the service was under heavy load and a node went down as the handoff is delayed.

Last the queue is a list in the GenServer. This might have performance issues on adding messages to the end of the list if the queue was huge but I figure no reason to optimize it yet till it becomes an issue.

# Mix Tests

It doesn't have the best coverage but I will add more later if need be

```bash
mix test
```

# Test just using iex

If you want to just test it using iex and curl you can start two iex sessions, in different bash windows, with these commands:

```bash
PORT=4000 iex --sname node1 --cookie foo -S mix
PORT=4001 iex --sname node2 --cookie foo -S mix
```

Then you can run a curl like the following to add messages to each instense that are now clustered using libcluster. Each adds 500 messages to a test queue

```bash
curl "http://0.0.0.0:4000/receive-message?queue=test&message=test[1-500]"
curl "http://0.0.0.0:4001/receive-message?queue=test&message=test[501-1000]"
```

# Test using Docker and Docker-Compose

I build a quick dockerfile and docker-compose file to build this in a docker container as well as a nginx proxy to handle load balancing the service which will work fine for running locally with Docker Engine.

This does expose it to port 4000 so if something else is running on that port you might need to update the docker-compose.yml file to another port.

To start the docker containers with 3 app works:

```bash
docker-compose up --scale app=3
```

Now in another window you can run curls like this adding 500 messages to 3 different queues,

```bash
curl "http://0.0.0.0:4000/receive-message?queue=test1&message=test[1-500]"
curl "http://0.0.0.0:4000/receive-message?queue=test2&message=test[1-500]"
curl "http://0.0.0.0:4000/receive-message?queue=test3&message=test[1-500]"
```

Now you could run a docker stop on any one of thoses containers and it will move the queue to another node and continue processing messages where it left off.