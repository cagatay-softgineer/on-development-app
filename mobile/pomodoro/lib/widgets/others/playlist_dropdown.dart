import 'package:flutter/material.dart';
import 'package:pomodoro/models/playlist.dart';
import 'package:pomodoro/resources/themes.dart';

Future<void> showPlaylistSelectorDialog({
  required BuildContext context,
  required List<Playlist> playlists,
  required Playlist? selected,
  required ValueChanged<Playlist> onSelected,
}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: 'Playlist Selector',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.90,
            constraints: const BoxConstraints(maxHeight: 440),
            decoration: BoxDecoration(
              color: ColorPalette.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.gold.withOpacity(0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Playlist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ColorPalette.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: playlists.isEmpty
                      ? Center(
                          child: Text(
                            'No playlists found.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: playlists.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white12, height: 12),
                          itemBuilder: (context, idx) {
                            final playlist = playlists[idx];
                            final isSelected = playlist == selected;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                onSelected(playlist);
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorPalette.gold.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: FadeInImage.assetNetwork(
                                        placeholder: 'assets/placeholder.png',
                                        image: playlist.playlistImage.isNotEmpty
                                            ? playlist.playlistImage
                                            : 'https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Placeholder/PNG/Placeholder-Rectangle%400.5x.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        imageErrorBuilder: (_, __, ___) => Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.black26,
                                          child: Icon(Icons.music_note, color: Colors.white60),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            playlist.playlistName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: ColorPalette.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            playlist.playlistOwner,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white54,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check, color: ColorPalette.gold, size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}