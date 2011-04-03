package tansu
{
	import com.adobe.webapis.flickr.FlickrService;
	import com.adobe.webapis.flickr.PagedPhotoList;
	import com.adobe.webapis.flickr.Photo;
	import com.adobe.webapis.flickr.PhotoTag;
	import com.adobe.webapis.flickr.User;
	import com.adobe.webapis.flickr.events.FlickrResultEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	public class FlickrPhotos extends EventDispatcher
	{
		private var flickrService:FlickrService;
		private var flickrUser:User;
		
		private var _cloth:Object = {};
		private var _fashion:Object = {};
		
		/***
		Photo Idを以下のように分類する (人別に分類した方が良いかも)
		{
			cloth: { tsuka: {inners:[id1,id2], outers:[], bottoms:[]}, ... },
			fashion: { tsuka: [id1,id2], ... }
		}
		***/
		
		public function FlickrPhotos(flickr:FlickrService, user:User)
		{
			this.flickrService = flickr;
			this.flickrUser = user;
		}
		
		public function load():void {
			loadFlickrTags();
		}
		
		public function get fashion():Object {
			return this._fashion;
		}
		
		public function get cloth():Object {
			return this._cloth;
		}

		//
		// タグ読み込み
		//
		private function loadFlickrTags():void {
			// まずタグ一覧を読む
			flickrService.addEventListener(FlickrResultEvent.TAGS_GET_LIST_USER,
				function(event:FlickrResultEvent):void {
					if (event.success) {
						// 人の名前を抜き出す
						var names:Array = pickOutNames(User(event.data.user).tags);
						trace(names);
						searchAllPhotos(names);
					} else {
						trace("error: tags");
					}
				});
			flickrService.tags.getListUser();
		}
		
		private function pickOutNames(tags:Array):Array {
			var obj:Object = {};
			for each (var tag:PhotoTag in tags) {
				var m:Array = tag.tag.match(/^name(.+)$/);
				if (m && m.length >= 2) {
					obj[m[1]] = 1;
				}
			}
			var names:Array = [];
			for (var n:String in obj) {
				if (n != "kambara" && n != "other") {
					names.push(n);
				}
			}
			return names;
		}
		
		//
		// 画像読み込み
		//
		private var searchTags:Array;
		private var searchingTag:Object;
		
		private function searchAllPhotos(names:Array):void {
			flickrService.addEventListener(FlickrResultEvent.PHOTOS_SEARCH, onPhotosSearch);
			
			// 検索用のタグの組み合わせを作る {type:~, name:~}
			searchTags = [];
			var types:Array = ["fashion", "outer", "inner", "bottom"];
			for each (var type:String in types) {
				for each (var name:String in names) {
					searchTags.push({
						name: name,
						type: type
					});
				}
			}
			// 検索開始
			searchNext();
		}
		
		private function searchNext():void {
			if (searchTags.length > 0) {
				searchPhotosOf(searchTags.shift());
			} else {
				// 全検索終了
				trace("done!!");
				dispatchEvent(new Event("load"));
			}
		}
		
		private function onPhotosSearch(event:FlickrResultEvent):void {
			var photos:Array = PagedPhotoList(event.data.photos).photos;
			addPhotos(photos);
			setTimeout(function():void {
				searchNext();
			}, 500);
		}
		
		private function searchPhotosOf(tag:Object):void {
			searchingTag = tag;
			flickrService.photos.search(flickrUser.nsid, [
				"name" + tag.name,
				"type" + tag.type
			].join(','), "all");
		}
		
		//
		// Photo追加
		//
		private function addPhotos(photos:Array):void {
			trace(searchingTag.name+" x "+searchingTag.type+" = "+photos.length);
			if (photos.length > 0) {
				if (searchingTag.type == "fashion") {
					addPhotosToFashion(photos, searchingTag.name);
				} else {
					addPhotosToCloth(photos, searchingTag.name, searchingTag.type);
				}
			}
		}
		private function addPhotosToFashion(photos:Array, name:String):void {
			if (!_fashion[name]) {
				_fashion[name] = [];
			}
			for each (var p:Photo in photos) {
				_fashion[name].push(p);
			}
		}
		private function addPhotosToCloth(photos:Array, name:String, type:String):void {
			if (!_cloth[name]) {
				_cloth[name] = {
					inners: [],
					outers: [],
					bottoms: []
				}
			}
			for each (var p:Photo in photos) {
				_cloth[name][type+"s"].push(p);
			}
		}
	}
}