import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.black, brightness: Brightness.light)),
      home: SocketIOExample(),
    );
  }
}

class SocketIOExample extends StatefulWidget {
  @override
  _SocketIOExampleState createState() => _SocketIOExampleState();
}

class _SocketIOExampleState extends State<SocketIOExample> {
  // final String serverUrl = 'http://127.0.0.1:12000';
  late Socket socket;
  int trackNum = 0; // 等一下要改
  late Widget _list = Text("Wait");
  TextEditingController messageController = TextEditingController();
  List<String> messages = [];

  static const IconData shuffle = IconData(0xe5a1, fontFamily: 'MaterialIcons');

  // server ip port
  String _serverIp = "172.20.10.3";
  int _serverPort = 12000;

  // volume
  double _sliderValue = 0.0;

  // play / stop
  IconData _iconPlay = Icons.play_arrow;
  bool isPlay = false;

  // icon
  bool _connect = false;
  IconData _iconConnect = Icons.cancel;

  void connectToServer(ip, port) async {
    // print(port);
    try {
      socket = await Socket.connect(ip, port);
      _connect = true;
      socket.write("7");
      socket.listen((var rcv) {
        String msg = utf8.decode(rcv);

        trackNum = int.parse(msg);
        print('trackNum:$trackNum');
        setState(() {
          _list = ListView.builder(
            scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            itemCount: trackNum,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  var sendmsg = "6|${(index + 1).toString()}";
                  print(sendmsg);
                  socket.write(sendmsg);
                  setState(() {
                    _iconPlay = Icons.pause;
                  });
                  isPlay = true;
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.lightGreen,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFE8E8E8),
                            offset: Offset(8, 8),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ]),
                    height: 100.0,
                    width: 100.0,
                    child: Center(
                        child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Goudy Stout'),
                    )),
                  ),
                ),
              );
            },
          );
        });
      }, onDone: () {
        _connect = false;
        print('Done');
      }, onError: (e) {
        _connect = false;
        setState(() {
          _iconConnect = Icons.reset_tv;
          _list = const Text("Disconnect");
        });
        print('Got error $e');
        socket.close();
      });
    } on SocketException catch (e) {
      _connect = false;
      setState(() {
        _list = const Text("Disconnect");
        _iconConnect = Icons.reset_tv;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    connectToServer(_serverIp, _serverPort);
  }

  // Function to send a message to the server.
  void sendMessage() {
    String message = messageController.text;
    if (message.isNotEmpty) {
      socket.write(message);
      messageController.clear();
    }
  }

  // updateVolumes() async {
  //   maxVol = await Volume.getMaxVol;
  //   currentVol = await Volume.getVol;
  //   setState(() {});
  // }

  void _showFontSizePickerDialog() async {
    // <-- note the async keyword here

    // this will contain the result from Navigator.pop(context, result)
    final selectedVolume = await showDialog<double>(
      context: context,
      builder: (context) => VolumeDialog(initialVolume: _sliderValue),
    );

    // execution of this code continues when the dialog was closed (popped)

    // note that the result can also be null, so check it
    // (back button or pressed outside of the dialog)
    if (selectedVolume != null) {
      print("8|${selectedVolume.toInt.toString()}");
      socket.write("8|${selectedVolume.toInt().toString()}");
      setState(() {
        _sliderValue = selectedVolume;
      });
    }
  }

  // setVol(int i) {
  //   currentVol = i;
  // }

  @override
  void dispose() {
    socket.close();
    // socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
            child: Center(
              child: Container(
                // color: Colors.green,
                height: 500.0,
                width: 150.0,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(color: Colors.grey, offset: Offset(6, 6)),
                    ]),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
                  child: _list,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 140.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    // padding: const EdgeInsets.all(10.0),
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_connect) {
                              socket.close();
                              setState(() {
                                _iconConnect = Icons.reset_tv;
                                _list = const Text("Disconnect");
                              });
                            } else {
                              connectToServer(_serverIp, _serverPort);
                              setState(() {
                                _iconConnect = Icons.cancel;
                              });
                            }
                          },
                          icon: Icon(
                            _iconConnect,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                      flex: 3,
                      // padding: EdgeInsets.all(10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              size: 50,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _showFontSizePickerDialog();
                            },
                          ),
                        ),
                      )),
                  Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _iconPlay,
                              size: 50,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              if (isPlay) {
                                setState(() {
                                  _iconPlay = Icons.play_arrow;
                                });
                                socket.write("1|0");
                                isPlay = false;
                              } else {
                                setState(() {
                                  _iconPlay = Icons.pause;
                                });
                                socket.write("1|1");
                                isPlay = true;
                              }
                            },
                          ),
                        ),
                      ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VolumeDialog extends StatefulWidget {
  final double? initialVolume;

  const VolumeDialog({super.key, this.initialVolume});
  // const VolumeDialog({required Key key, this.initialVolume}) : super(key: key);

  @override
  _VolumeDialogState createState() => _VolumeDialogState();
}

class _VolumeDialogState extends State<VolumeDialog> {
  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      title: Text('Volume'),
      content: SizedBox(
        height: 100,
        width: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              children: <Widget>[
                Slider(
                  activeColor: Colors.indigoAccent,
                  min: 0.0,
                  max: 30.0,
                  value: _volume,
                  label: _volume.round().toString(),
                  onChanged: (double newRating) {
                    setState(() {
                      _volume = newRating;
                    });
                    // setVol(newRating.toInt());
                    // await updateVolumes();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text("Submit"),
          onPressed: () {
            Navigator.pop(context, _volume);
          },
        )
      ],
    );
  }
}
