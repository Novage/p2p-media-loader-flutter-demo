class P2PStats {
  double totalHttpDownloaded;
  double totalP2PDownloaded;
  double totalP2PUploaded;
  List<String> activePeers;

  P2PStats({
    this.totalHttpDownloaded = 0,
    this.totalP2PDownloaded = 0,
    this.totalP2PUploaded = 0,
    this.activePeers = const [],
  });
}
