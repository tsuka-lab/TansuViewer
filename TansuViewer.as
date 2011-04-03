package {
	import com.adobe.webapis.flickr.AuthPerm;
	import com.adobe.webapis.flickr.AuthResult;
	import com.adobe.webapis.flickr.FlickrService;
	import com.adobe.webapis.flickr.User;
	import com.adobe.webapis.flickr.events.FlickrResultEvent;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.IME;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	import tansu.ClothLoopSwitcher;
	import tansu.FashionLoopSwitcher;
	import tansu.FlickrPhotos;
	import tansu.LoopSwitcher;

	public class TansuViewer extends Sprite
	{
		/*
		Todo:
		- スピード変化
		- 幅が足りないときどうするか
		*/
		
		private var fashionLoopSwitcher:LoopSwitcher;
		private var clothLoopSwitcher:LoopSwitcher;
		private var fashionMode:Boolean = false;
		
		private var flickrService:FlickrService;
		private var flickrUser:User;
		private var flickrPhotos:FlickrPhotos;
		
		public function TansuViewer()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
			IME.enabled = false;
			
			startFlickrAuth();
			//this.loadLocalImageList();
		}
		
		private function jsAlert(msg:String):void {
			var js:String = 'javascript:alert("' + msg + '")';
			navigateToURL(new URLRequest(js), "_self");
		}
		
		//
		// Flickr認証
		//
		private function startFlickrAuth():void {
			// flickr authentication
			flickrService = new FlickrService("43114d7f0b0351d485313c13ca46a981");
			flickrService.secret = "e5733f461269e80f";
			
			var flickrCookie:SharedObject = SharedObject.getLocal("TansuViewer");
			var cachedToken:String = flickrCookie.data.authToken || null;
			if (cachedToken) {
				// キャッシュしたTokenをチェック
				trace("cached token: "+cachedToken);
				flickrService.addEventListener(FlickrResultEvent.AUTH_CHECK_TOKEN,
					function(checkEvent:FlickrResultEvent):void {
						if (checkEvent.success) {
							// 問題なければこのTokenを使う
							finishFlickrAuth(checkEvent.data.auth);
						} else {
							trace("The cached token is invalid.");
							loadFrob();
						}
					});
				flickrService.auth.checkToken(cachedToken);
			} else {
				trace("A cached token is not exist.");
				loadFrob();
			}
		}
		
		private function finishFlickrAuth(authResult:AuthResult):void {
			flickrService.token = authResult.token;
			flickrService.permission = authResult.perms;
			//flickrService.permission = AuthPerm.READ;
			flickrUser = authResult.user;
			
			trace(authResult.user.username);
			trace(flickrService.permission);
			
			// 写真情報読み込み
			flickrPhotos = new FlickrPhotos(flickrService, flickrUser);
			flickrPhotos.addEventListener("load", function():void {
				addLoopSwitchers();
			});
			flickrPhotos.load();
		}
		
		private function loadFrob():void {
			flickrService.addEventListener(FlickrResultEvent.AUTH_GET_FROB,
				function(frobEvent:FlickrResultEvent):void {
					if (frobEvent.success) {
						var frob:String = String(frobEvent.data.frob);
						loadFlickrToken(frob); // 次はTokenをロード
					} else {
						trace("error: flickr.getFrob");
					}
				});
			flickrService.auth.getFrob();
		}
		
		private function loadFlickrToken(frob:String):void {
			// ブラウザからFlickrにログインしてもらう
			var authUrl:String = flickrService.getLoginURL(frob, AuthPerm.READ);
			navigateToURL(new URLRequest(authUrl), "_blank");
			
			// Flickrにログインしたよボタンを表示
			var button:Sprite = createAfterLoginButton();
			button.addEventListener(MouseEvent.CLICK, function():void {
				// トークンを取得
				flickrService.addEventListener(FlickrResultEvent.AUTH_GET_TOKEN, onLoadFlickrToken);
				flickrService.auth.getToken(frob);
				// ボタンは削除
				button.parent.removeChild(button);
			});
			button.x = 10;
			button.y = 10;
			addChild(button);
		}
		
		private function onLoadFlickrToken(tokenEvent:FlickrResultEvent):void {
			if (tokenEvent.success) {
				var authResult:AuthResult = tokenEvent.data.auth;
				// トークンをキャッシュ
				var flickrCookie:SharedObject = SharedObject.getLocal("TansuViewer");
				flickrCookie.data.authToken = authResult.token;
				flickrCookie.flush();
				
				finishFlickrAuth(authResult);
			} else {
				jsAlert("error: cannot get a flickr token");
			}
		}
		
		private function createAfterLoginButton():Sprite {
			var label:TextField = new TextField();
			label.text = "I have logged in to Flickr.";
			label.setTextFormat(new TextFormat(null, 22, 0x9999FF, true, null, true));
			label.autoSize = TextFieldAutoSize.LEFT;
			label.selectable = false;
			
			var button:Sprite = new Sprite();
			button.addChild(label);
			return button;
		}
		
		//
		// 画像リスト読み込み (obsolete)
		//
		/***
		private function loadLocalImageList():void {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, function():void {
				jsAlert("Error: assets/image-list.txt is not exist.");
			});
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function():void {
				jsAlert("Security Error: can not load assets/image-list.txt");
			});
			loader.addEventListener(Event.COMPLETE, function():void {
				addLoopSwitchers( parseImageList(String(loader.data)) );
			});
			try {
				loader.load(new URLRequest("assets/image-list.txt"));
			} catch (e:Error) {
				jsAlert("Security Error: " + e.name + " " + e.message);
			}
		}
		***/
		
		/***
		private function parseImageList(data:String):Array {
			return data.split(
				/\r\n|\r|\n/
			).filter(function(item:*, index:int, array:Array):Boolean {
				// 空文字を取り除いて
				return (item && String(item).length > 0);
			}).map(function(item:*, index:int, array:Array):String {
				// パスにディレクトリ名を追加
				return "assets/images/" + String(item);
			});
		}
		***/
		
		private function addLoopSwitchers():void {
			////var pathData:Object = classifyPathes(list);
			
			fashionLoopSwitcher = new FashionLoopSwitcher();
			clothLoopSwitcher = new ClothLoopSwitcher();
			addChild(fashionLoopSwitcher);
			addChild(clothLoopSwitcher);
			
			// まずfashionループ群を生成
			fashionLoopSwitcher.addEventListener("loaded", function():void {
				// 次にclothループ群を生成
				trace("cloth loop");
				clothLoopSwitcher.addEventListener("loaded", function():void {
					trace("cloth loaded");
					// イベント設定
					setupKeyEvents();
					// リサイズ
					clothLoopSwitcher.resize();
					fashionLoopSwitcher.resize();
					// 初期表示
					showCurrentLoopSwitcher();
					// 動き始める
					clothLoopSwitcher.startMove();
					fashionLoopSwitcher.startMove();
				});
				clothLoopSwitcher.addLoops(flickrPhotos.cloth);
			});
			fashionLoopSwitcher.addLoops(flickrPhotos.fashion);
		}
		
		/***
		パスを以下のように分類する (これは人別に分類した方が良かったな)
		{
			cloth: { tsuka: {inners:[p1,p2], outers:[], bottoms:[]}, ... },
			fashion: { tsuka: [p1,p2], ... }
		}
		***/
		/***
		private function classifyPathes(list:Array):Object {
			var clothPeople:Object = {}; 
			var fashionPeople:Object = {};
			
			// パスを人・種類別に分類
			for each (var path:String in list) {
				// 000_0_tsuka_outer_123.jpg などにマッチ
				var m:Array = path.match(/_([^_]+)_(outer|inner|bottom|fashion)/);
				if (!m) continue;
				var name:String = m[1];
				var type:String = m[2];
				
				if (type == "fashion") {
					if (!fashionPeople[name]) {
						fashionPeople[name] = [];
					}
					fashionPeople[name].push(path);
				} else {
					// outer, inner, bottom
					if (!clothPeople[name]) {
						clothPeople[name] = {
							outers: [],
							inners: [],
							bottoms: []
						};
					}
					if (type == "outer") {
						clothPeople[name].outers.push(path);
					} else if (type == "inner") {
						clothPeople[name].inners.push(path);
					} else if (type == "bottom") {
						clothPeople[name].bottoms.push(path);
					}
				}
			}
			return {
				cloth: clothPeople,
				fashion: fashionPeople
			}
		}
		***/
		
		//
		// キーイベント
		//
		private function setupKeyEvents():void {
			stage.addEventListener(KeyboardEvent.KEY_UP, function(keyEvent:KeyboardEvent):void {
				switch (keyEvent.keyCode) {
					case Keyboard.NUMPAD_0:
					case 48: // テンキーではない0
						switchLoopSwitcher();
						break;
					case Keyboard.NUMPAD_9:
					case 57:
						switchPeople();
						break;
				}
			});
		}
		
		//
		// 人を切り替え
		//
		private function switchPeople():void {
			currentLoopSwitcher().switchPeople();
		}
		
		private function currentLoopSwitcher():LoopSwitcher {
			if (fashionMode) {
				return fashionLoopSwitcher;
			} else {
				return clothLoopSwitcher;
			}
		}
		
		//
		// ClothとFashionの切り替え
		//
		private function switchLoopSwitcher():void {
			var curName:String = currentLoopSwitcher().currentName();
			
			fashionMode = !fashionMode;
			// もし同じ人がいればその人に切り替える
			currentLoopSwitcher().switchPeopleTo(curName);
			this.showCurrentLoopSwitcher();
		}
		
		private function showCurrentLoopSwitcher():void {
			this.clothLoopSwitcher.visible = !fashionMode;
			this.fashionLoopSwitcher.visible = fashionMode;
		}
	}
}
