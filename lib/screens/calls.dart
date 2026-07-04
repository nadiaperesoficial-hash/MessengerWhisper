import 'package:flutter/material.dart';
import 'package:whatsapp_redesign/model/calls_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class Calls extends StatelessWidget {
  Calls(this.listType, {super.key});
  final String listType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(listType),
        titleSpacing: -1.0,
        leading: IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: callMockData.length,
        itemBuilder: (context, position) => Padding(
          padding: const EdgeInsets.all(0.0),
          child: Card(
            elevation: 1.0,
            color: Colors.white,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                        callMockData[position].profileImageUrl),
                    backgroundColor: Colors.grey,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        callMockData[position].name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Icon(
                        callMockData[position].callSource == 'video'
                            ? Icons.videocam
                            : Icons.call,
                        color: AppColors.lineGreen,
                      ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                callMockData[position].day,
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey),
                              ),
                              const Text(
                                ' | ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                              Text(
                                callMockData[position].time,
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Text(
                            callMockData[position].callType,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
