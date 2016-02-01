package {
	import flash.events.NetStatusEvent;
	import flash.display.Sprite;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.MouseEvent;
	import flash.media.Microphone;
	import flash.events.ActivityEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.StatusEvent;
	import fl.controls.ProgressBarMode;
	import flash.display.Shape;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.external.ExternalInterface;
	import flash.display.LoaderInfo;

	public class Recorder extends Sprite {
		// private members
		private var nc:NetConnection;
		private var ns:NetStream;
		private var mic:Microphone;
		private var showTimer:Timer;
		private var volumeTimer:Timer;
		private var secs:uint;
		private var vsecs:uint;
		private var fileName:String;
		private var shapes:Array;
		// 外部传入变量区
		// 16/8
		private var samplerate:int = 16;
		// e.g. localhost
		private var host:String = "192.168.0.71";
		private var debug:Boolean = false;


		public function Recorder() {
			// 设置音量进度条
			progressBar.mode = ProgressBarMode.MANUAL;
			progressBar.minimum = 0;
			progressBar.maximum = 100;
			// 设置并检查录音参数
			var paramObj:Object = LoaderInfo(root.loaderInfo).parameters;
			if(paramObj.debug != undefined)
				debug = (paramObj.debug == "true");
			if(paramObj.samplerate != undefined)
				samplerate = int(paramObj.samplerate);
			log("set samplerate = " + samplerate);
			if(paramObj.host != undefined){
				host = paramObj.host;
			}
			log("set host = " + host);
			
			lbHint.text = "Click and Sing/Hum";
			lbHint.addEventListener(MouseEvent.CLICK,lbHint_onClick);
			lbHint.addEventListener(MouseEvent.MOUSE_OVER,lbHint_onMouseOver);
			lbHint.addEventListener(MouseEvent.MOUSE_OUT,lbHint_onMouseOut);
		}
		
		private function log(msg:String){
			trace(msg);
			if(debug){
				ExternalInterface.call("log",msg);
			}
		}
		
		public function lbHint_onMouseOut(ev:MouseEvent):void {
			lbHint.alpha = 0.5;
		}
		public function lbHint_onMouseOver(ev:MouseEvent):void {
			lbHint.alpha = 1;
		}
		public function lbHint_onClick(ev:MouseEvent):void {
			trace("lbHint clicked");
			if (lbHint.text == "Click to Sing/Hum") {// start recording
				lbHint.text = "Connecting...";
				nc = new NetConnection();
				nc.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler);
				nc.connect("rtmp://" + host + "/recorder");
			} else {// stop recording 
				lbHint.text = "Click to Sing/Hum";
				trace("stop recording");
				//nc.close();
				stopRecord();
				// 提交录音数据
				ExternalInterface.call("submit",fileName);
			}
		}

		public function stopRecord():void {
			ns.close();
			// 停止录音计时
			showTimer.stop();
			// 停止音量检测
			volumeTimer.stop();
			// 播放录音
			//ns.play(false);
			//ns = new NetStream(nc);
			//ns.play(fileName);
		}
		public function publishStream():void {

			// NetStream
			ns = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler);
			ns.client = new CustomClient();

			// Microphone
			mic = Microphone.getMicrophone();
			if (mic == null) {// 麦克风正在使用中
				trace("麦克风无法获取");
			}
			mic.rate = 44;
			log("set samplerate = " + samplerate);
			mic.setLoopBack(false);
			mic.setUseEchoSuppression(true);
			mic.setSilenceLevel(10);
			mic.addEventListener(ActivityEvent.ACTIVITY,onMicActivityHandler);
			mic.addEventListener(StatusEvent.STATUS,onMicStatusHandler);

			if (mic != null) {
				// start publishing audio
				// trigger NetStream.Publish.Start
				trace("start publishing audio");
				mic.addEventListener(ActivityEvent.ACTIVITY,activityHandler);
				ns.attachAudio(mic);
				if (mic.muted) {
					trace("麦克风请求被拒绝");
					//Security.showSettings(SecurityPanel.DEFAULT);
				}// 拒绝麦克风请求
				var dt:Date = new Date();
				fileName = dt.getTime() + "" + Math.random();
				fileName = fileName.replace("0.",".");
				//ns.publish(fileName,"record");
				ns.publish("test","record");
				// Set lbHint text
				lbHint.text = "Click To Stop";
				// 录音时间显示设置
				secs = 0;
				showTimer = new Timer(1000,0);
				showTimer.start();
				showTimer.addEventListener(TimerEvent.TIMER,showTimer_timerHandler);
				// 音量检测计时器
				vsecs = 0;
				volumeTimer = new Timer(20,0);
				volumeTimer.addEventListener(TimerEvent.TIMER,volumeTimer_timerHandler);
				volumeTimer.start();
				// 录音波形显示
				if (shapes != null && shapes.length > 0) {
					shapes.forEach(removeFromScene);
				}
				shapes = new Array();
			} else {
				trace("unable to publish audio to sever,please check your microphone");
			}
		}
		private function removeFromScene(e:*,index:int,arr:Array):void {
			removeChild(e);
		}
		/*
		 * 麦克风活动回调函数
		 */
		public function onMicActivityHandler(ev:ActivityEvent):void {
			trace("mic_activity: activiting=" + ev.activating + ",activityLevel=" + mic.activityLevel);
		}
		/*
		 * 麦克风状态回调函数
		 */
		public function onMicStatusHandler(ev:StatusEvent):void {
			trace("mic_status: level=" + ev.level + ", code=" + ev.code);
		}
		public function volumeTimer_timerHandler(ev:TimerEvent):void {
			if (mic.activityLevel > 0) {
				progressBar.value = mic.activityLevel;
				vsecs += 20;
				if (vsecs % 200 == 0) {// 整秒
					var shape:Shape = new Shape();
					shape.graphics.beginFill(0xFFCC00);
					shape.graphics.lineStyle(0,0x666666);
					shape.graphics.moveTo(40 + vsecs / 200, 40);
					shape.graphics.lineTo(40 + vsecs / 200, 40 - mic.activityLevel/5);
					shape.graphics.endFill();
					shapes.push(shape);
					addChild(shape);
				}
			}
		}
		/**
		 * 录音计时间隔处理函数
		 */
		public function showTimer_timerHandler(ev:TimerEvent):void {
			secs += 1;
			var s:String = secs.toString();
			if (s.length == 1) {
				s = "0" + s;
			}
			s = "0:" + s;
			lbTime.text = s;
		}
		public function activityHandler(ev:ActivityEvent):void {
			trace("activityHandler: " + ev);
			trace("activiting: " + ev.activating);
		}
		public function netStatusHandler(ev:NetStatusEvent):void {
			trace("NetStatus.info.level : " + ev.info.level);
			trace("NetStatus.info.code : " + ev.info.code);
			switch (ev.info.code) {
				case "NetConnection.Connect.Success" :
					trace("connection successfully");
					publishStream();
					break;
				case "NetConnection.Connect.Failed" :
					trace("connection failed");
					break;
				case "NetConnection.Connect.Rejected" :
					trace("connection rejected");
					break;
				case "NetConnection.Connect.Closed" :
					trace("connection closed");
					break;
				case "NetStream.Publish.Start" :
					trace("start publishing");
					break;
				case "NetStream.Record.Start" :
					break;
				case "NetStream.Record.Stop" :
					trace("netstream.record.stop");
					break;
				case "NetStream.Unpublish.Success" :
					break;
				default :
					trace("unhandled netstatus " + ev.info.code);
					break;
			}
		}
	}
}

class CustomClient {
	public function onMetaData(info:Object):void {
		trace("width: " + info.width);
		trace("height: " + info.height);
	}
	public function onPlayStatus(info:Object):void {
		trace("onPlayStatus: " + info.info.code);
	}
}