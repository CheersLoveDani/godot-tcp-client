extends Control


# Declare the TCP client object
var tcp_client: StreamPeerTCP
var connecting = false
var connected = false

@onready var status_indicator = $ColorRect

var message_text = ""

func _ready():
	status_indicator.color = Color(1, 0, 0)


func connect_to_server():
	# Initialize the TCP client
	if connected:
		print("Already connected to the server.")
		return

	tcp_client = StreamPeerTCP.new()

	# Attempt to connect to the server (IP and port)
	var connection_status = tcp_client.connect_to_host("127.0.0.1", 8080)
	var timeout = 20
	print("Connection status: ", connection_status)
	while connection_status == OK && tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTING && timeout > 0:
		await get_tree().create_timer(1).timeout
		timeout -= 1
		print("Connecting... ", timeout)
		connecting = true

	if timeout == 0:
		print("Connection timed out.")
		connecting = false
		connected = false
		return
		

	if connection_status == OK:
		print("Connected to the server.")
		connected = true
	else:
		print("Failed to connect to the server.")

# Function to send a message_text to the server
func send_message(message: String):
	if connected:
		# Convert the message_text to bytes and send it
		var bytes = message.to_utf8_buffer()
		# print("bytes: ", bytes)
		var sent = tcp_client.put_data(bytes)
		# print("Sent: ", sent)
		if sent == OK:
			print("Message sent: ", message)
		else:
			print("Failed to send message.")
	else:
		print("Not connected to the server.")

# Function to receive the response from the server
func receive_response():
	if connected:
		# Check how many bytes are available to read
		var available = tcp_client.get_available_bytes()
		if available > 0:
			# Read the response from the server
			var received_data = tcp_client.get_data(available)
			if received_data.size() > 0 && received_data[0] == 0:
				var data_string = received_data[1].get_string_from_utf8()
				var response = String(data_string)
				print("Received response: ", response)
			else:
				print("No data received.")
		# else:
		# 	print("No available bytes to read.")

# Called every frame to keep the connection alive and receive data
func _process(delta):
	if connecting || connected:
		tcp_client.poll()
		var result = tcp_client.get_status()
		if result == StreamPeerTCP.STATUS_CONNECTING:
			status_indicator.color = Color(1, 1, 0) # Yellow
		elif result == StreamPeerTCP.STATUS_CONNECTED:
			status_indicator.color = Color(0, 1, 0) # Green
		elif result == StreamPeerTCP.STATUS_ERROR or result == StreamPeerTCP.STATUS_NONE:
			status_indicator.color = Color(1, 0, 0) # Red

		if result == StreamPeerTCP.STATUS_ERROR or result == StreamPeerTCP.STATUS_NONE:
			print("Disconnected from server.")
			connected = false
			connecting = false
		else:
			receive_response()

func _on_connect_button_pressed():
	connect_to_server()

func _on_text_edit_text_changed():
	message_text = get_node("MarginContainer/VBoxContainer/TextEdit").text


func _on_send_button_pressed():
	send_message(message_text)
