const socket = new WebSocket("ws://localhost:4000/ws");

socket.addEventListener("open", function(event) {
  socket.send("ping");
});

socket.addEventListener("message", function(event) {
  console.log("Message from socket server:", event.data);
});
