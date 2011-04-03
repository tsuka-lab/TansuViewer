package tansu
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	//
	// ClothLoopとFashionLoop用の抽象クラス
	// 人ごとのClothLoopやClothLoopを持ち、それらを切り替える。
	//
	public class LoopSwitcher extends Sprite
	{
		protected var currentIndex:uint;
		protected var peopleNames:Array;
		protected var loopTable:Object; // 人ごとのclothLoopまたはfashionLoop
		
		public function LoopSwitcher()
		{
			super();
			currentIndex = 0;
			peopleNames = [];
			loopTable = {};
		}
		
		public function currentName():String {
			return peopleNames[currentIndex];
		}
		
		protected function currentLoop():* {
			return loopTable[currentName()];
		}
		
		
		
		public function addLoops(pathData:Object):void {
			var names:Array = [];
			for (var name:String in pathData) {
				names.push(name);
				peopleNames.push(name);
			}
			addNextLoop(names, pathData);
		}
		
		private function addNextLoop(names:Array, pathData:Object):void {
			if (!names || names.length == 0) {
				setupKeyEvents();
				showCurrentIndexLoop();
				dispatchEvent(new Event("loaded"));
				return;
			}
			
			// 一人取り出してループを追加
			var name:String = names.shift();
			trace(name +" - 残り:"+names);
			var loop:* = createLoop(pathData[name]); // clothLoop or fashionLoop
			loopTable[name] = loop; // 一覧に追加しておく
			loop.addEventListener("loaded", function():void {
				addNextLoop(names, pathData);
			});
			addChild(loop);
		}
		
		public function showCurrentIndexLoop():void {
			var curName:String = peopleNames[currentIndex];
			for (var key:String in loopTable) {
				Sprite(loopTable[key]).visible = (key == curName);
			}
		}
		
		public function switchPeople():void {
			currentIndex += 1;
			if (currentIndex > peopleNames.length-1) {
				currentIndex = 0;
			}
			showCurrentIndexLoop();
		}
		
		public function switchPeopleTo(name:String):void {
			var index:int = this.nameToIndex(name);
			if (index < 0) return;
			this.currentIndex = index;
			showCurrentIndexLoop();
		}
		private function nameToIndex(name:String):int {
			for (var i:int = 0; i<peopleNames.length; i++) {
				if (peopleNames[i] == name) {
					return i;
				}
			}
			return -1;
		}
		
		public function resize():void {
		}
		
		protected function setupKeyEvents():void { // Abstract
		}
		
		protected function createLoop(pathData:*):* { // Abstract
		} 
		
		public function startMove():void { // Abstract
		}
	}
}