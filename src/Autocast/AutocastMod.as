package Autocast 
{
	
	import Bezel.Bezel;
	import Bezel.BezelMod;
	import flash.display.MovieClip;
	/**
	 * ...
	 * @author Chris
	 */
	public class AutocastMod extends MovieClip implements BezelMod
	{
		
		private var autocast:Object;
		
		public function AutocastMod() 
		{
			super();
		}

		public function get VERSION():String { return "1.3"; }
		public function get GAME_VERSION():String { return "1.2.1a"; }
		public function get BEZEL_VERSION():String { return "1.0.0"; }
		public function get MOD_NAME():String { return "Autocast"; }
		
		public function bind(bezel:Bezel, gameObjects:Object): void
		{
			autocast = new Autocast(bezel, gameObjects);
		}
		
		public function unload(): void
		{
			if (autocast != null)
			{
				autocast.unload();
				autocast = null;
			}
		}
		
	}

}
