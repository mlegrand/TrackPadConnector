package com.multitouchup.trackPadConnector
{
	import com.utils.NetworkUtil;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.TouchEvent;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.NetworkInfo;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.ByteArray;
	
	import org.tuio.connectors.UDPConnector;
	import org.tuio.osc.IOSCListener;
	import org.tuio.osc.OSCManager;
	import org.tuio.osc.OSCMessage;
	
	[Bindable]
	public class TrackPadConnector extends EventDispatcher implements IOSCListener
	{
		
		private static var instance : TrackPadConnector;
		
		public var touchPoints:Array = new Array();
		protected var flashStage:Stage;
		protected var numberOfActiveTouchPoints:int;
		protected var doubleCheckTouchPoints:Array = new Array();
		protected var drawnTouchPoints:Array = new Array();
		protected var dCanvas:Sprite;
		protected var oscManager:OSCManager;
		protected var fseq:uint = 0;
		protected var src:String = '';
		protected var _tuioCursors:Array = new Array();
		
		protected var tongsengFile:File;
		protected var tongsengProcess:NativeProcess;
		
		
		
		/**
		 * Singelton class for connecting to SimTouch or other UDP touch emulators.
		 *
		 * @param       port
		 * @param       location
		 * @param       target
		 */
		public function TrackPadConnector(stage:Stage, 
										  debuggerCanvas:Sprite = null, 
										  location:String = null, 
										  port:Number = 3333,
										  target:IEventDispatcher=null)
		{
			super(target);
			if ( instance != null )
			{
				throw new Error("SimConnect is a singleton class and can only have one instance." );
			}
			
			if(!location)
			{
				location = NetworkUtil.getIpAddress(NetworkInfo.networkInfo.findInterfaces());
			}
			if(NativeProcess.isSupported)
			{
				startTongsengTUIODispatcher(location, port);
			}
			else
			{
				throw Error('Native Process is not supported.  Please check that your Air descriptor file has ' +
					'<supportedProfiles>extendedDesktop desktop</supportedProfiles>' +
					'Your Air Descriptor file is typically located in your application root with the name of YOUR_APP-app.xml' +
					'Your application also has to be packaged as a native application.')
			}
			
			this.flashStage = stage;
			
			this.flashStage.nativeWindow.addEventListener(Event.CLOSING, nativeWindow_closingHandler)
			
			
			this.oscManager = new OSCManager(new UDPConnector(location, port, true));
			this.oscManager.addMsgListener(this);
			if(tongsengProcess.running)
			{
				trace('listener started? : '+location+' : ' +port.toString());
			}

			instance = this;
			if(debuggerCanvas)
			{
				this.dCanvas = debuggerCanvas
			}
		}
		
		
		protected function startTongsengTUIODispatcher(location:String, port:Number):void
		{
			tongsengFile = File.applicationDirectory.resolvePath("tongseng");
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			nativeProcessStartupInfo.arguments.push(location, port);
			nativeProcessStartupInfo.executable = tongsengFile;
			tongsengProcess = new NativeProcess();
			tongsengProcess.start(nativeProcessStartupInfo);
			tongsengProcess.addEventListener(NativeProcessExitEvent.EXIT, processExit_eventHandler)
			if(tongsengProcess.running)
			{
				trace('process started? : '+location+' : ' +port.toString());
			}
		}
		
		protected function processExit_eventHandler(e:NativeProcessExitEvent):void
		{
			trace('process exited');
		}
		
		
		
		public function acceptOSCMessage(msg:OSCMessage):void
		{
			var tuioContainerList:Array;
			
			if (msg.arguments[0] == "fseq") {
				var newFseq:uint = uint(msg.arguments[1]);
				if (newFseq != this.fseq) {
					//dispatchNewFseq();
					this.fseq = newFseq;
				}
			} 
			else if (msg.arguments[0] == "source") this.src = String(msg.arguments[1]);
			else if (msg.arguments[0] == "set"){
				
				var isObj:Boolean = false;
				var isBlb:Boolean = false;
				var isCur:Boolean = false;
				
				var is2D:Boolean = false;
				var is25D:Boolean = false;
				var is3D:Boolean = false;
				
				if (msg.address.indexOf("/tuio/2D") == 0) {
					is2D = true;
				} else if (msg.address.indexOf("/tuio/25D") == 0) {
					is25D = true;
				} else if (msg.address.indexOf("/tuio/3D") == 0) {
					is3D = true;
				} else return;
				
				if (msg.address.indexOf("cur") > -1) {
					isCur = true;
				} else if (msg.address.indexOf("obj") > -1) {
					isObj = true;
				} else if (msg.address.indexOf("blb") > -1) {
					isBlb = true;
				} else return;
				
				var s:Number = 0;
				var i:Number = 0;
				var x:Number = 0, y:Number = 0, z:Number = 0;
				var a:Number = 0, b:Number = 0, c:Number = 0;
				var X:Number = 0, Y:Number = 0, Z:Number = 0;
				var A:Number = 0, B:Number = 0, C:Number = 0;
				var w:Number = 0, h:Number = 0, d:Number = 0;
				var f:Number = 0;
				var v:Number = 0;
				var m:Number = 0, r:Number = 0;
				
				var index:uint = 2;
				
				s = Number(msg.arguments[1]);
				
				if (isObj) {
					i = Number(msg.arguments[index++]);
				}
				
				x = Number(msg.arguments[index++]);
				y = Number(msg.arguments[index++]);
				
				x = x * this.flashStage.width;
				y = y * this.flashStage.height;
				
				if (!is2D) {
					z = Number(msg.arguments[index++]);
				}
				
				if (!isCur) {
					a = Number(msg.arguments[index++]);
					if (is3D) {
						b = Number(msg.arguments[index++]);
						c = Number(msg.arguments[index++]);
					}
				}
				
				if (isBlb) {
					w = Number(msg.arguments[index++]);
					h = Number(msg.arguments[index++]);
					if (!is3D) {
						f = Number(msg.arguments[index++]);
					} else {
						d = Number(msg.arguments[index++]);
						v = Number(msg.arguments[index++]);
					}
				}
				
				X = Number(msg.arguments[index++]);
				Y = Number(msg.arguments[index++]);
				
				if (!is2D) {
					Z = Number(msg.arguments[index++]);
				}
				
				if (!isCur) {
					A = Number(msg.arguments[index++]);
					if (msg.address.indexOf("/tuio/3D") == 0) {
						B = Number(msg.arguments[index++]);
						C = Number(msg.arguments[index++]);
					}
				}
				
				m = Number(msg.arguments[index++]);
				
				if (!isCur) {
					r = Number(msg.arguments[index++]);
				}
				
				//generate object
				
				var type:String = msg.address.substring(6, msg.address.length);
				
				var tuioDataValueObject:TuioDataValueObject;
				
				if (isCur) {
					tuioContainerList = this._tuioCursors;
				}
				else return;
				
				//resolve if add or update
				for each(var tc:TuioDataValueObject in tuioContainerList) {
					if (tc.sessionID == s) {
						tuioDataValueObject = tc;
						break;
					}
				}
				
				if(tuioDataValueObject == null){
					if (isCur) {
						tuioDataValueObject = new TuioCursor(type, s, x, y, z, X, Y, Z, m, this.fseq);
						this._tuioCursors.push(tuioDataValueObject);
						dispatchTouchDown(tuioDataValueObject)
						//dispatchAddCursor(tuioContainer as TuioCursor);
					} else return;
					
				} else {
					if (isCur) {
						(tuioDataValueObject as TuioCursor).update(x, y, z, X, Y, Z, m, this.fseq);
						//
						dispatchTouchMove(tuioDataValueObject);
						//dispatchUpdateCursor(tuioContainer as TuioCursor);
					} else return;
				}
				
			} else if (msg.arguments[0] == "alive") {
				
				if (msg.address.indexOf("cur") > -1) {
					
					for each(var tcur:TuioCursor in this._tuioCursors) {
						tcur.isAlive = false;
					}
					
					for (var k:uint = 1; k < msg.arguments.length; k++){
						for each(tcur in this._tuioCursors) {
							if (tcur.sessionID == msg.arguments[k]) {
								tcur.isAlive = true;
								break;
							}
						}
					}
					
					tuioContainerList = this._tuioCursors.concat();
					this._tuioCursors = new Array();
					
					for each(tcur in tuioContainerList) {
						if (tcur.isAlive) this._tuioCursors.push(tcur);
						else {
							dispatchTouchUp(tcur)
						}
					}
					
				}
			}
		}
		
		//
		//  Draw Touch Points
		//
		
		protected function addTouchObject(t:TuioDataValueObject) : void
		{
			var ui:Sprite = new Sprite();
			var g:Graphics = ui.graphics;
			var m:Matrix = new Matrix();
			m.createGradientBox(20,20, 0, -10, -10)
			g.beginGradientFill(GradientType.RADIAL, [0x666666, 0xFFFFFF], [0.25,0.5], [0, 255], m, SpreadMethod.REFLECT);
			g.lineStyle(4, 0, 0.25)
			g.drawCircle(0,0, 20);
			ui.height = 20;
			ui.width = 20;
			
			drawnTouchPoints[t.sessionID] = ui;
			
			dCanvas.addChild(ui);
			
			//(flashStage.getChildAt(flashStage.numChildren-1) as UIComponent).addChild(ui);
			ui.x = t.x;
			ui.y = t.y;
		}
		
		protected function updateTouchObject(t:TuioDataValueObject):void
		{
			drawnTouchPoints[t.sessionID].x = t.x;
			drawnTouchPoints[t.sessionID].y = t.y;
		}
		
		protected function removeTouchObject(t:TuioDataValueObject):void
		{
			dCanvas.removeChild(drawnTouchPoints[t.sessionID]);
			delete drawnTouchPoints[t.sessionID];
		}
		
		//
		//  Dispatch touch events
		//
		
		
		protected function dispatchTouchUp(t:TuioDataValueObject):void
		{
			var currentTargets:Array= getTargets(new Point(t.x, t.y), TouchEvent.TOUCH_END);
			for each(var currentTarget:DisplayObject in currentTargets)
			{
				var p:Point = currentTarget.globalToLocal(new Point(t.x, t.y))
				currentTarget.dispatchEvent(new TouchEvent(TouchEvent.TOUCH_END,
					true, false, t.sessionID, false, p.x, p.y));
			}
			
			// debug canvas
			
			if(dCanvas)
			{
				removeTouchObject(t);
			}
		}
		
		
		protected function dispatchTouchDown(t:TuioDataValueObject):void
		{
			var currentTargets:Array= getTargets(new Point(t.x, t.y), TouchEvent.TOUCH_BEGIN);			
			for each(var currentTarget:DisplayObject in currentTargets)
			{
				var p:Point = currentTarget.globalToLocal(new Point(t.x, t.y))
				currentTarget.dispatchEvent(new TouchEvent(TouchEvent.TOUCH_BEGIN,
					true, false, t.sessionID, false, p.x, p.y));
			}
			
			// debug canvas
			
			if(dCanvas)
			{
				addTouchObject(t);
			}
		}
		
		protected function dispatchTouchMove(t:TuioDataValueObject):void
		{
			var currentTargets:Array= getTargets(new Point(t.x, t.y), TouchEvent.TOUCH_MOVE);
			for each(var currentTarget:DisplayObject in currentTargets)
			{
				var p:Point = currentTarget.globalToLocal(new Point(t.x, t.y))
				currentTarget.dispatchEvent(new TouchEvent(TouchEvent.TOUCH_MOVE,
					true, false, t.sessionID, false, p.x, p.y, 0, 0, 0, null, false, false, false, false,false));
			}
			
			// debug canvas
			
			if(dCanvas)
			{
				updateTouchObject(t);
			}
		}
		
		
		//
		// helper functions
		//
		
		protected function makeNumberPositive(number:Number) : Number
		{
			var r:Number;
			(number < 0)? r = number*-1 : r = number;
			return r;
		}
		
		protected function getTargets(p:Point, eventType:String) : Array
		{
			var a:Array = [];
			for each(var ed:EventDispatcher in flashStage.getObjectsUnderPoint(p))
			{
				a.push(ed);
			}
			return a;
		}
		
		
		//
		//  Event handlers
		//
		
		protected function nativeWindow_closingHandler(event:Event):void
		{
			if(tongsengProcess.running)
			{
				tongsengProcess.exit(true);
			}
		}
		
	}
}