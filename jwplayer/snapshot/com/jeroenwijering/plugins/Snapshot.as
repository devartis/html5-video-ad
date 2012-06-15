package com.jeroenwijering.plugins {


import com.adobe.images.JPGEncoder;
import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.Logger;
import com.longtailvideo.jwplayer.utils.RootReference;

import flash.display.*;
import flash.events.*;
import flash.net.*;
import flash.system.*;
import flash.utils.*;
import flash.text.*


/**
* This plugins renders a JPG snapshot from a video frame.
* It sends the JPG to a serverside script for processing and displays the returning URL.
*
* Alternatively, the player can send just a position variable to the server.
* The server then has to take care of rendering the snapshot.
**/
public class Snapshot extends MovieClip implements PluginInterface {


	/** Background image. **/
	private var back:Sprite;
	/** The bitmap object to use for storing the snapshot contents. **/
	private var bitmap:BitmapData;
	/** List with configuration settings. **/
	public var config:Object = {
		bitmap:true,
		script:undefined
	};
	/** Instance of the object that will encode the snapshot. **/
	private var encoder:JPGEncoder;
	/** The textfield showing all messages. **/
	private var field:TextField;
	/** Loader that sends the jpg data and retrieves the image url. **/
	private var loader:URLLoader;
	/** The current position inside the video. **/
	private var position:Number;
	/** A snap has been made recently. **/
	private var snapshot:String;
	/** Reference to the View of the player. **/
	private var view:AbstractView;


	/** Constructor; set security directive for the download dialog. **/
	public function Snapshot():void {
		Security.allowDomain("*");
		bitmap = new BitmapData(320,240,false,0x000000);
		encoder = new JPGEncoder(90);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		buildStage();
	};


	/** Build all stage graphics. **/
	private function buildStage():void {
		back = new Sprite();
		back.buttonMode = true;
		back.graphics.beginFill(0x000000,0.6);
		back.graphics.drawRect(0,0,400,20);
		back.graphics.beginFill(0x000000,0.7);
		back.graphics.drawRect(0,20,400,20);
		addChild(back);
		field = new TextField();
		field.defaultTextFormat = new TextFormat('_sans',13,0xFFFFFF,null,null,null,null,null,TextFormatAlign.CENTER);
		field.mouseEnabled = false;
		field.y = 10;
		addChild(field);
	};


	/** Invoked when the span button is clicked; it'll setup and send the servercall. **/
	private function clickHandler(evt:MouseEvent):void {
		if(snapshot) {
			Logger.log('Redirecting to '+snapshot,'snapshot');
			navigateToURL(new URLRequest(snapshot),view.config['linktarget']);
		} else if (position) {
			Logger.log('Taking snapshot at '+position,'snapshot');
			snap();
		} else {
			Logger.log('Playing the video','snapshot');
			view.sendEvent('PLAY','true');
		}
	};


	/** The initialize call is invoked by the player View. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		view.addModelListener(ModelEvent.META,metaHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		back.addEventListener(MouseEvent.CLICK,clickHandler);
		resizeHandler();
		stateHandler();
	};


	/** Reload the video after a timeout. **/
	private function loaderHandler(evt:Event):void {
		var txt:String = loader.data as String;
		Logger.log('Script returned '+txt,'snapshot');
		if(txt.indexOf('http://') ==  0) {
			view.config['image'] = snapshot = txt;
			field.htmlText = 'Snapshot sent; <u>click to return</u> or select another frame.';
		} else { 
			field.htmlText = 'Error: '+txt;
		}
		back.buttonMode = true;
	};


	/** When metadata is received, build a new bitmap object with the right dimensions. **/
	private function metaHandler(evt:ModelEvent):void {
		if(evt.data.width && evt.data.height) {
			bitmap = new BitmapData(evt.data.width,evt.data.height,false,0x000000);
		}
	};


	/** Handle a resize of the display. **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		if(config['width']) {
			x = config['x'];
			y = config['y'];
			back.width = field.width = config['width'];
		} else {
			back.width = field.width = view.config['width'];
		}
		field.x = 0;
	};


	/** Encode a bitmap of the video. **/
	private function snap():void {
		view.sendEvent('PLAY',false);
		field.htmlText = 'Sending snapshot, please wait...';
		back.buttonMode = false;
		var req:URLRequest = new URLRequest(view.config['snapshot.script']);
		req.method = URLRequestMethod.POST;
		if(config['bitmap']) {
			try {
				bitmap.draw(videoObject());
				req.requestHeaders.push(new URLRequestHeader("Content-type","application/octet-stream"));
				req.data = encoder.encode(bitmap);
				loader.load(req);
				Logger.log('Sending snapshot to '+view.config['snapshot.script'],'snapshot');
			} catch(err:SecurityError) {
				field.htmlText = err.message;
				//field.htmlText = "Security error: no crossdomain.xml or 302 redirect on video.";
			}
		} else {
			var fil:String = encodeURI(view.playlist[view.config['item']]['file']);
			req.data = new URLVariables('file='+fil+'&position='+position);
			loader.load(req);
			Logger.log('Sending position to '+view.config['snapshot.script'],'snapshot');
		}
	};


	/** Save the current position in the video; needed for a snapshot later on. **/
	private function stateHandler(evt:ModelEvent=null):void {
		switch(view.config['state']) {
			case ModelStates.COMPLETED:
			case ModelStates.IDLE:
				field.htmlText = "<u>Start the video to select a frame</u>";
			case ModelStates.PLAYING:
				snapshot = undefined;
				break;
		}
	};


	/** Save the current position in the video; needed for a snapshot later on. **/
	private function timeHandler(evt:ModelEvent):void {
		position = Math.round(evt.data.position*10)/10;
		var pos:String = position.toString();
		if(pos.indexOf('.') == -1) { pos += '.0'; }
		field.htmlText = "<u>Select frame at "+pos+" seconds</u>";
	};


	/** Grab the video object - nasty hack that depends on player version. **/
	private function videoObject():DisplayObject { 
		var ply:String = view.config['version'].substr(0,3);
		switch (ply) {
			case '4.6':
			case '4.7':
				return view.skin.display.media.getChildAt(0) as DisplayObject;
			case '4.5':
				return view.skin.display.media as DisplayObject;
			case '4.4':
			case '4.3':
			case '4.2':
			case '4.1':
				view.skin.display.media.mask = null;
				return view.skin.display.media as DisplayObject;
			default:
				var skn:Sprite =  RootReference.stage.getChildAt(0) as Sprite;
				return Sprite(skn.getChildAt(1)).getChildAt(0) as DisplayObject;
		}
	};


};


}