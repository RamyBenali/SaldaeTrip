import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Container(
          width: 428,
          height: 926,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 26,
                top: 93,
                child: Text(
                  'Hotel',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontFamily: 'Abril Fatface',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: 27,
                top: 148,
                child: Container(
                  width: 371,
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 327,
                        height: 48,
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF0D8BFF),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Color(0xFFC4C4C4), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Search ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFC4C4C4),
                                    fontSize: 16,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      child: Stack(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(FontAwesomeIcons.sliders, color: Color(0xFF0D8BFF), size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 6.50,
                top: 222,
                child: Container(
                  width: 415,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FEBF3FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        top: 0,
                        child: Container(
                          width: 353,
                          height: 125,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: 8.50,
                                child: Container(
                                  width: 126,
                                  height: 108,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "assets/Rectangle 14.png",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 126,
                                top: 23,
                                child: Container(
                                  width: 237,
                                  height: 79,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hotel Atlantis',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontFamily: 'Actor',
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: -0.44,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Color(0xFFC4C4C4)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'RN N 09 IRIYAHEN, Béjaia',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'ABeeZee',
                                                        fontWeight:
                                                        FontWeight.w400,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '15k DZD/',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Nuit',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0D8BFF,
                                                      ),
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 118,
                                        top: 65,
                                        child: Container(
                                          width: 50,
                                          height: 14,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.9/3k ',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'ABeeZee',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 5,
                top: 359,
                child: Container(
                  width: 415,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FEBF3FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        top: 0,
                        child: Container(
                          width: 353,
                          height: 125,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: 8.50,
                                child: Container(
                                  width: 126,
                                  height: 108,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "assets/Rectangle 15.png",
                                      ),
                                      fit: BoxFit.fill,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 126,
                                top: 23,
                                child: Container(
                                  width: 237,
                                  height: 79,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hotel Saldae',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontFamily: 'Actor',
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: -0.44,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Color(0xFFC4C4C4)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Forêt des olivier, Béjaïa',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'ABeeZee',
                                                        fontWeight:
                                                        FontWeight.w400,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '15k DZD/',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Nuit',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0D8BFF,
                                                      ),
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 118,
                                        top: 65,
                                        child: Container(
                                          width: 50,
                                          height: 14,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.9/3k ',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'ABeeZee',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 496,
                child: Container(
                  width: 415,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FEBF3FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        top: 0,
                        child: Container(
                          width: 353,
                          height: 125,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: 8.50,
                                child: Container(
                                  width: 126,
                                  height: 108,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "assets/Rectangle 16.png",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 126,
                                top: 23,
                                child: Container(
                                  width: 237,
                                  height: 79,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hotel du nord',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontFamily: 'Actor',
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: -0.44,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Color(0xFFC4C4C4)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Bd Colonel Amirouche, Béjaïa',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'ABeeZee',
                                                        fontWeight:
                                                        FontWeight.w400,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '9k DZD/',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Nuit',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0D8BFF,
                                                      ),
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 118,
                                        top: 65,
                                        child: Container(
                                          width: 50,
                                          height: 14,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.9/3k ',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'ABeeZee',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 7,
                top: 635,
                child: Container(
                  width: 415,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FEBF3FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        top: 0,
                        child: Container(
                          width: 353,
                          height: 125,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: 8.50,
                                child: Container(
                                  width: 126,
                                  height: 108,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "assets/Rectangle 17.png",
                                      ),
                                      fit: BoxFit.fill,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 126,
                                top: 23,
                                child: Container(
                                  width: 237,
                                  height: 79,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hotel du Lac',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontFamily: 'Actor',
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: -0.44,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Color(0xFFC4C4C4)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Rte de la Briqueterie, Béjaïa',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'ABeeZee',
                                                        fontWeight:
                                                        FontWeight.w400,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '7k DZD/',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Nuit',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0D8BFF,
                                                      ),
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 118,
                                        top: 65,
                                        child: Container(
                                          width: 50,
                                          height: 14,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.9/3k ',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'ABeeZee',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 7,
                top: 776,
                child: Container(
                  width: 415,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FEBF3FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        top: 0,
                        child: Container(
                          width: 353,
                          height: 125,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: 8.50,
                                child: Container(
                                  width: 126,
                                  height: 108,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "assets/Rectangle 18.png",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 126,
                                top: 23,
                                child: Container(
                                  width: 237,
                                  height: 79,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hotel Golden H',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontFamily: 'Actor',
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: -0.44,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Color(0xFFC4C4C4)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Rue Frères Tabet, Béjaia',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'ABeeZee',
                                                        fontWeight:
                                                        FontWeight.w400,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '9k DZD/',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Nuit',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0D8BFF,
                                                      ),
                                                      fontSize: 12,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                      FontWeight.w400,
                                                      letterSpacing: -0.24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 118,
                                        top: 65,
                                        child: Container(
                                          width: 50,
                                          height: 14,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.9/3k ',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'ABeeZee',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 428,
                  height: 52,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 383.87,
                        top: 20.48,
                        child: Opacity(
                          opacity: 0.35,
                          child: Container(
                            width: 25.11,
                            height: 13.39,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFF333333),
                                ),
                                borderRadius: BorderRadius.circular(2.67),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 386.15,
                        top: 22.85,
                        child: Container(
                          width: 20.54,
                          height: 8.67,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF333333),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1.33),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 23.97,
                        top: 8.27,
                        child: Container(
                          width: 61.63,
                          height: 24.82,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 8,
                                child: SizedBox(
                                  width: 61.63,
                                  child: Text(
                                    '9:41',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF333333),
                                      fontSize: 15,
                                      fontFamily: 'Avenir',
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}