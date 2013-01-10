Player = function(videoElement) {
	this.player = _V_(videoElement);
    this.player.tag.crossOrigin = '';
    this.canvas = this.createCanvas();
    this.isPlayingAd = false;
}

Player.prototype.play = function() {
    this.player.play();
}

Player.prototype.pause = function() {
    this.player.pause();
}

Player.prototype.currentTime = function() {
    this.player.currentTime();
}

Player.prototype.volume = function(vol) {
    this.player.volume(vol);
}

Player.prototype.autoPlay = function() {
    var self = this;
    var player = this.player;
    player.ready(function(){
        player.play();
        setTimeout(function() {self.processFrame()}, 0);
    });
}

Player.prototype.preload = function() {
    var player = this.player;
    player.ready(function() {
        player.play();
    });
    player.addEvent('loadeddata', function() {
        player.pause();
        player.currentTime(0);
        player.removeEvent('loadeddata');
    });
}

Player.prototype.onAdStart = function(event) {
    this.onAdStartEvent = event;
}

Player.prototype.onAdStop = function(event) {
    this.onAdStopEvent = event;
}

Player.prototype.processFrame = function() {
    var self = this;
    var context = this.canvas.getContext('2d');
    context.drawImage(this.player.tag, 672, 15, 15, 15, 0, 0, 15, 15);
    var rgb = this.calculateAverageColor(context.getImageData(0, 0, 15, 15));

    if (!this.isPlayingAd && rgb[0] <= 20 && rgb[1] <= 20 && rgb[2] >= 250) {
        this.onAdStartEvent();
        this.isPlayingAd = true;
    }
    if (this.isPlayingAd && !(rgb[0] <= 20 && rgb[1] <= 20 && rgb[2] >= 250)) {
        this.onAdStopEvent();
        this.isPlayingAd = false;
    }

    setTimeout(function() {self.processFrame()}, 100);
}

Player.prototype.createCanvas = function() {
    var canvas = document.createElement('canvas');
    canvas.width = 640;
    canvas.height = 264;
    document.getElementsByTagName('body')[0].appendChild(canvas);

    return canvas;
}

Player.prototype.calculateAverageColor = function(idata) {
    var data = idata.data;
    var avg_r = 0;
    var avg_g = 0;
    var avg_b = 0;

    for(var i = 0; i < data.length; i+=4) {
        var r = data[i];
        var g = data[i+1];
        var b = data[i+2];
        avg_r += r;
        avg_g += g;
        avg_b += b;
    }
    avg_r = Math.round(avg_r / (data.length / 4));
    avg_g = Math.round(avg_g / (data.length / 4));
    avg_b = Math.round(avg_b / (data.length / 4));

    return [avg_r, avg_g, avg_b];
}