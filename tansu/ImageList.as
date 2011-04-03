package tansu
{
	import com.adobe.webapis.flickr.Photo;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.setTimeout;

	public class ImageList extends Sprite
	{
		private var images:Array = [];

		public function ImageList()
		{
			super();
			//this.cacheAsBitmap = true;
		}
		
		public function load(photos:Array, h:uint):void {
			// とりあえず画像はLoaderで並べておく。
			addNextImage(photos, 0, h);
		}
		
		public function clone():ImageList {
			var list:ImageList = new ImageList();
			/*
			list.graphics.beginFill(0xFF0000);
			list.graphics.drawRect(0, 0, 100, 100);
			list.graphics.endFill();
			*/
			for each (var bmp:Bitmap in images) {
				var newBmp:Bitmap = new Bitmap(bmp.bitmapData.clone());
				newBmp.width = bmp.width;
				newBmp.height = bmp.height;
				newBmp.x = bmp.x;
				list.addImage(newBmp);
			}
			return list;
		}
		
		public function setHeight(h:Number):void {
			var prevRight:Number = 0;
			for each (var img:Bitmap in images) {
				img.width = Math.round(img.width * h / img.height);
				img.height = h;
				// 左に詰める
				img.x = prevRight;
				prevRight = img.x + img.width;
			}
		}
		
		public function getImageAt(x:Number):Bitmap {
			for each (var img:Bitmap in images) {
				if (img.x <= x && img.x + img.width > x) {
					return img;
				}
			}
			return null;
		}
		
		private function addNextImage(photos:Array, prevRight:uint, h:uint):void {
			if (!photos || photos.length == 0) {
				dispatchEvent(new Event("loaded"));
				return;
			}
			
			var photo:Photo;
			try {
				photo = Photo(photos.shift());
				//trace(photo.id + " "+photo.tags);
			} catch (e:Error) {
				//trace(e.message);
				return addNextImage(photos, prevRight, h);;
			}
			
			var path:String = [
				"http://farm",
				photo.farmId,
				".static.flickr.com/",
				photo.server,
				"/",
				photo.id,
				"_",
				photo.secret,
				"_m", // m(small-240) s(small square-75) t(thumb-100) b(large-1024)
				".jpg"
			].join('');
			
			//trace("load: "+path);
			var imgLoader:Loader = new Loader();
			imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void {
				//trace("Load Error: "+path);
				addNextImage(photos, prevRight, h);
			});
			imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function():void {
				/***
				imgLoader.width = Math.round(imgLoader.content.width * h / imgLoader.content.height);
				imgLoader.height = h;
				imgLoader.x = prevRight;
				//addChild(imgLoader);
				//images.push(imgLoader);
				***/
				
				var bmp:Bitmap = Bitmap(imgLoader.content);
				bmp.width = Math.round(imgLoader.content.width * h / imgLoader.content.height);
				bmp.height = h;
				bmp.x = prevRight;
				addImage(bmp);
				
				setTimeout(function():void {
					addNextImage(photos, bmp.x + bmp.width, h); // 次の画像
				}, 500);
			});
			imgLoader.load(new URLRequest(path), new LoaderContext(true));
		}
		
		public function addImage(bmp:Bitmap):void {
			addChild(bmp);
			images.push(bmp);
		}
	}
}