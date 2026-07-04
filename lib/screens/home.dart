import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp_redesign/model/chat_model.dart';
import 'package:whatsapp_redesign/model/stories_model.dart';
import '../core/theme/app_theme.dart';
import 'new_chat_screen.dart';

class Home extends StatelessWidget {
  final String listType;
  Home(this.listType, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Whisper',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamily: 'Roboto',
          ),
        ),
        titleSpacing: 16.0,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
        },
      ),
      body: Column(
        children: <Widget>[
          const Padding(padding: EdgeInsets.fromLTRB(0.0, 3.0, 0.0, 8.0)),
          Container(
            height: 220.0,
            color: Colors.grey[200],
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: storiesMockData.length,
                itemBuilder: (context, int position) => Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                          child: Container(
                            color: Colors.grey[200],
                            width: 100.0,
                            height: 210.0,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image:
                                                  CachedNetworkImageProvider(
                                                      storiesMockData[position]
                                                          .storyImageUrl),
                                              fit: BoxFit.cover),
                                          borderRadius:
                                              BorderRadius.circular(10.0)),
                                      width: 100.0,
                                      height: 140.0,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            5.0, 85.0, 5.0, 5.0),
                                        child: Text(
                                          storiesMockData[position].name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                              fontStyle: FontStyle.normal,
                                              color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      5.0, 65.0, 5.0, 0.0),
                                  child: PhysicalModel(
                                    borderRadius: BorderRadius.circular(25.0),
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 50.0,
                                      height: 50.0,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                                storiesMockData[position]
                                                    .profileImageUrl),
                                            fit: BoxFit.cover),
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                        border: Border.all(
                                          width: 3.0,
                                          color: storiesMockData[position]
                                                  .storySeen
                                              ? Colors.grey
                                              : const Color(0xFF2845E7),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        5.0, 140.0, 5.0, 0.0),
                                    child: Center(
                                      child: Text(
                                        storiesMockData[position].day,
                                      ),
                                    )),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      5.0, 172.0, 5.0, 0.0),
                                  child:
                                      Text(storiesMockData[position].time),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),
          ),
          Expanded(
            child: ListView.builder(
                itemBuilder: (context, position) {
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                      child: Card(
                          elevation: 1.0,
                          color: const Color(0xFFFFFFFF),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  ChatMockData[position].imageUrl),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  ChatMockData[position].name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ChatMockData[position].time,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14.0),
                                ),
                              ],
                            ),
                            subtitle: Container(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                ChatMockData[position].message,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 15.0),
                              ),
                            ),
                          )));
                },
                itemCount: ChatMockData.length),
          )
        ],
      ),
    );
  }
}
