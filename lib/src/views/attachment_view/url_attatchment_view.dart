// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';

import '../../chat_view_model/chat_view_model_client.dart';
import '../../providers/interface/attachments.dart';
import '../../styles/file_attachment_style.dart';

/// A widget that displays a file attachment.
///
/// This widget creates a container with a file icon and information about the
/// attached file, such as its name and MIME type.
@immutable
class UrlAttachmentView extends StatefulWidget {
  /// Creates a UrlAttachmentView.
  ///
  /// The [attachment] parameter must not be null and represents the
  /// file attachment to be displayed.
  const UrlAttachmentView(this.attachment, {super.key});

  /// The file attachment to be displayed.
  final LinkAttachment attachment;

  @override
  State<UrlAttachmentView> createState() => _UrlAttachmentViewState();
}

class _UrlAttachmentViewState extends State<UrlAttachmentView> {
  String? thumbnailUrl;

  @override
  Widget build(BuildContext context) => ChatViewModelClient(
        builder: (context, viewModel, child) {
          final attachmentStyle = FileAttachmentStyle.resolve(
            viewModel.style?.fileAttachmentStyle,
          );

          return InkWell(
            onTap: () async{
              if (!await launchUrl(widget.attachment.url)) {
              debugPrint('couldnt open url');
              }
            },
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: attachmentStyle.decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    // decoration: attachmentStyle.iconDecoration,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: thumbnailUrl != null?DecorationImage(
                        image: NetworkImage(thumbnailUrl!),
                        fit: BoxFit.cover,
                      ):null,
                    ),

                    // child: thumbnailUrl != null
                    //     ? Image.network(thumbnailUrl!,fit: BoxFit.cover,) // Display the fetched image
                    //     : CircularProgressIndicator(),
                  ),

                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.attachment.name,
                          style: attachmentStyle.filenameStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.attachment.url.toString(),
                          style: attachmentStyle.filetypeStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Future<void> fetchThumbnail() async {
    try {
      final response = await http.get(widget.attachment.url);
      if (response.statusCode == 200) {
        // Parse the HTML content
        dom.Document document = parse(response.body);

        // Try to find the Open Graph thumbnail (og:image) or a default image tag
        final ogImage = document.querySelector('meta[property="og:image"]')?.attributes['content'];

        // If og:image isn't found, fall back to the first image in the page
        if (ogImage != null) {
          setState(() {
            thumbnailUrl = ogImage;
          });
        } else {
          // Optionally handle a fallback if no thumbnail is found
          final imgTag = document.querySelector('img')?.attributes['src'];
          if (imgTag != null) {
            setState(() {
              thumbnailUrl = imgTag;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching thumbnail: $e');
    }
  }
  @override
  void initState() {
    super.initState();
    fetchThumbnail();
  }
}
