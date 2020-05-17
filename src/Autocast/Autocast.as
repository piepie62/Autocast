package Autocast 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.filesystem.*;
	import flash.events.*;
	import flash.globalization.LocaleID;
	import flash.utils.*;
	
	public class Autocast extends MovieClip
	{
		public const VERSION:String = "1.1";
		public const GAME_VERSION:String = "1.1.0a";
		public const BEZEL_VERSION:String = "0.2.1";
		public const MOD_NAME:String = "Autocast";
		
		internal var gameObjects:Object;
		
		// Game object shortcuts
		internal var core:Object;/*IngameCore*/
		internal var cnt:Object;/*CntIngame*/
		internal var GV:Object;/*GV*/
		internal var SB:Object;/*SB*/
		internal var prefs:Object;/*Prefs*/
		
		// Mod loader object
		public static var bezel:Object;
		internal static var logger:Object;
		internal static var storage:File;
		
		private var casters:Object;
		public var markerSpellType:int;
		private var frameCounter:int;
		
		private static var spellRangeCircles:Array;
		
		public function Autocast() 
		{
			super();
		}
		
		public function bind(modLoader:Object, gameObjects:Object): Autocast
		{
			bezel = modLoader;
			logger = bezel.getLogger("Autocast");
			this.gameObjects = gameObjects;
			this.core = gameObjects.GV.ingameCore;
			this.cnt = gameObjects.GV.main.cntScreens.cntIngame;
			this.SB = gameObjects.SB;
			this.GV = gameObjects.GV;
			this.prefs = gameObjects.prefs;
			storage = File.applicationStorageDirectory.resolvePath("Autocast");
			
			prepareFolders();
			
			addEventListeners();
			this.casters = new Object();
			this.markerSpellType = -1;
			this.frameCounter = 0;
			spellRangeCircles = new Array(this.cnt.mcRangeFreeze, this.cnt.mcRangeWhiteout, this.cnt.mcRangeIceShards);
			
			logger.log("bind", "Autocast initialized!");
			
			return this;
		}
		
		public function prettyVersion(): String
		{
			return 'v' + VERSION + ' for ' + GAME_VERSION;
		}
		
		/*private function checkForUpdates(): void
		{
			if(!this.configuration["Check for updates"])
				return;
			
			logger.log("CheckForUpdates", "Mod version: " + prettyVersion());
			logger.log("CheckForUpdates", "Checking for updates...");
			var repoAddress:String = "https://api.github.com/repos/gemforce-team/gemsmith/releases/latest";
			var request:URLRequest = new URLRequest(repoAddress);
			
			var loader:URLLoader = new URLLoader();
			var localThis:Gemsmith = this;
			
			loader.addEventListener(Event.COMPLETE, function(e:Event): void {
				var latestTag:Object = JSON.parse(loader.data).tag_name;
				var latestVersion:String = latestTag.replace(/[v]/gim, ' ').split('-')[0];
				localThis.updateAvailable = (latestVersion != VERSION);
				logger.log("CheckForUpdates", localThis.updateAvailable ? "Update available! " + latestTag : "Using the latest version: " + latestTag);
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent): void {
				logger.log("CheckForUpdates", "Caught an error when checking for updates!");
			});
			
			loader.load(request);
		}*/
		
		private function prepareFolders(): void
		{
			if (!storage.isDirectory)
			{
				storage.createDirectory();
			}
		}
		
		private function addEventListeners(): void
		{
			bezel.addEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			bezel.addEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			gameObjects.GV.main.addEventListener("enterFrame", eh_ingamePreRenderInfoPanel);
			bezel.addEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
		}
		
		public function unload(): void
		{
			removeEventListeners();
		}
		
		private function removeEventListeners(): void
		{
			bezel.removeEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			bezel.removeEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			bezel.removeEventListener("ingamePreRenderInfoPanel", eh_ingamePreRenderInfoPanel);
			gameObjects.GV.main.removeEventListener("enterFrame", eh_ingamePreRenderInfoPanel);
			bezel.removeEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			if (pE.ctrlKey)
			{
				if (pE.keyCode >= 49 && pE.keyCode <= 51)
				{
					e.eventArgs.continueDefault = false;
					if (this.core.arrIsSpellBtnVisible[pE.keyCode - 49])
					{
						this.markerSpellType = pE.keyCode - 49; //keyCode 49 is digit 1, which is freeze spell, which is spellType 0
						GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Entered marker placement mode!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
					}
					else
					{
						return;
					}
				}
			}
		}
		
		public function eh_ingameClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if(this.core.ingameStatus == gameObjects.constants.ingameStatus.PLAYING && this.markerSpellType != -1)
            {
				this.casters[this.markerSpellType] = new SpellCaster(this.GV.main.mouseX - 50, this.GV.main.mouseY - 8, this.markerSpellType);
				this.markerSpellType = -1;
				GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Added a new marker!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
			}
		}
		
		public function eh_ingameRightClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if(this.core.ingameStatus == gameObjects.constants.ingameStatus.PLAYING && this.markerSpellType != -1)
            {
				this.casters[this.markerSpellType] = null;
				GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Removed a marker!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
			}
			this.markerSpellType = -1;
		}
		
		public function eh_ingamePreRenderInfoPanel(e:Object): void
		{
			this.frameCounter++;
			if (this.frameCounter >= 15)
				this.castAtAllMarkers();
		}
		
		private function castAtAllMarkers(): void
		{
			for each (var caster:SpellCaster in this.casters) 
			{
				if (caster != null && SpellCaster.getSpellCharge(caster.spellType) >= SpellCaster.getMaxSpellCharge(caster.spellType))
				{
					caster.cast();
					SpellCaster.consumeSpellCharge(caster.spellType);
				}
			}
		}
	}
}