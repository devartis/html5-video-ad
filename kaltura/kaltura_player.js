KalturaPlayer = function(kdp) {
    this.kdp = kdp;
    this.kdp.crossOrigin = '';
}

KalturaPlayer.prototype.play = function() {
    this.kdp.sendNotification('doPlay');
}

KalturaPlayer.prototype.getVideo = function() {
    return $(this.kdp).find('video')[0];
}
