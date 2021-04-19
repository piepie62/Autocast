package Autocast 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import Bezel.Bezel;
	import Bezel.Events.EventTypes;
	import Bezel.Events.IngameClickOnSceneEvent;
	import Bezel.Events.IngameKeyDownEvent;
	import Bezel.Events.IngameNewSceneEvent;
	import Bezel.Events.IngamePreRenderInfoPanelEvent;
	import Bezel.Events.IngameRightClickOnSceneEvent;
	import Bezel.Logger;

	import com.giab.common.data.ENumber;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.constants.IngameStatus;
	import com.giab.games.gcfw.entity.Amplifier;
	import com.giab.games.gcfw.entity.Lantern;
	import com.giab.games.gcfw.entity.Tower;
	import com.giab.games.gcfw.entity.Trap;
	import com.giab.games.gcfw.ingame.IngameCore;
	import com.giab.games.gcfw.mcDyn.McRangeFreeze;
	import com.giab.games.gcfw.mcDyn.McRangeIceShards;
	import com.giab.games.gcfw.mcDyn.McRangeWhiteout;
	import com.giab.games.gcfw.mcStat.CntIngame;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.events.*;
	import flash.filesystem.*;
	
	public class Autocast
	{
		// Game object shortcuts
		internal var core:IngameCore;/*IngameCore*/
		internal var cnt:CntIngame;/*CntIngame*/
		
		// Mod loader object
		internal static var bezel:Bezel;
		internal static var logger:Logger;
		internal static var storage:File;
		
		private var casters:Vector.<SpellCaster>;
		public var markerSpellType:int;
		private var frameCounter:int;
		
		private static var spellRangeCircleSizes:Vector.<ENumber>;
		
		private static var iconBitmaps:Vector.<Bitmap>;
		
		private var spellImages:Vector.<MovieClip>;
		
		public function Autocast(modLoader:Bezel, gameObjects:Object) 
		{
			bezel = modLoader;
			logger = bezel.getLogger("Autocast");
			storage = File.applicationStorageDirectory.resolvePath("Autocast");
			
			this.core = GV.ingameCore;
			this.cnt = GV.ingameCore.cnt;
			
			prepareFolders();
			
			addEventListeners();
			this.casters = new Vector.<SpellCaster>(6);
			this.markerSpellType = -1;
			this.frameCounter = 0;
			this.spellImages = new Vector.<MovieClip>(6);
			this.spellImages[0] = new McRangeFreeze();
			this.spellImages[0].x = 50;
			this.spellImages[0].y = 8;
			this.spellImages[0].mcMask.width = 1680;
			this.spellImages[0].mcMask.height = 1064;
			this.spellImages[0].circle.visible = true;
			this.spellImages[0].visible = false;
			this.spellImages[1] = new McRangeWhiteout();
			this.spellImages[1].x = 50;
			this.spellImages[1].y = 8;
			this.spellImages[1].mcMask.width = 1680;
			this.spellImages[1].mcMask.height = 1064;
			this.spellImages[1].circle.visible = true;
			this.spellImages[1].visible = false;
			this.spellImages[2] = new McRangeIceShards();
			this.spellImages[2].x = 50;
			this.spellImages[2].y = 8;
			this.spellImages[2].mcMask.width = 1680;
			this.spellImages[2].mcMask.height = 1064;
			this.spellImages[2].circle.visible = true;
			this.spellImages[2].visible = false;
			spellRangeCircleSizes = new <ENumber>[this.core.spFreezeRadius, this.core.spWhiteoutRadius, this.core.spIsRadius];
			
			iconBitmaps = new Vector.<Bitmap>(3);
			iconBitmaps[0] = new Bitmap(GV.gemBitmapCreator.bmpdEnhIconBolt, PixelSnapping.ALWAYS, true);
			iconBitmaps[0].visible = true;
			iconBitmaps[1] = new Bitmap(GV.gemBitmapCreator.bmpdEnhIconBeam, PixelSnapping.ALWAYS, true);
			iconBitmaps[1].visible = true;
			iconBitmaps[2] = new Bitmap(GV.gemBitmapCreator.bmpdEnhIconBarrage, PixelSnapping.ALWAYS, true);
			iconBitmaps[2].visible = true;
			
			this.spellImages[3] = new MovieClip();
			this.spellImages[3].addChild(iconBitmaps[0]);
			this.spellImages[3].visible = false;
			this.spellImages[4] = new MovieClip();
			this.spellImages[4].addChild(iconBitmaps[1]);
			this.spellImages[4].visible = false;
			this.spellImages[5] = new MovieClip();
			this.spellImages[5].addChild(iconBitmaps[2]);
			this.spellImages[5].visible = false;
			
			logger.log("bind", "Autocast initialized!");
		}
		
		/*public function prettyVersion(): String
		{
			return 'v' + AutocastMod.VERSION + ' for ' + AutocastMod.GAME_VERSION;
		}*/
		
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
			bezel.addEventListener(EventTypes.INGAME_CLICK_ON_SCENE, eh_ingameClickOnScene);
			bezel.addEventListener(EventTypes.INGAME_KEY_DOWN, eh_interceptKeyboardEvent);
			bezel.addEventListener(EventTypes.INGAME_RIGHT_CLICK_ON_SCENE, eh_ingameRightClickOnScene);
			bezel.addEventListener(EventTypes.INGAME_PRE_RENDER_INFO_PANEL, eh_ingamePreRenderInfoPanel);
			bezel.addEventListener(EventTypes.INGAME_NEW_SCENE, onLevelStart);
		}
		
		public function unload(): void
		{
			removeEventListeners();
		}
		
		private function removeEventListeners(): void
		{
			bezel.removeEventListener(EventTypes.INGAME_CLICK_ON_SCENE, eh_ingameClickOnScene);
			bezel.removeEventListener(EventTypes.INGAME_KEY_DOWN, eh_interceptKeyboardEvent);
			bezel.removeEventListener(EventTypes.INGAME_RIGHT_CLICK_ON_SCENE, eh_ingameRightClickOnScene);
			bezel.removeEventListener(EventTypes.INGAME_PRE_RENDER_INFO_PANEL, eh_ingamePreRenderInfoPanel);
			bezel.removeEventListener(EventTypes.INGAME_NEW_SCENE, onLevelStart);
		}
		
		public function eh_interceptKeyboardEvent(e:IngameKeyDownEvent): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			if (pE.ctrlKey)
			{
				if (pE.keyCode >= 49 && pE.keyCode <= 54)
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
		
		public function eh_ingameClickOnScene(e:IngameClickOnSceneEvent): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if(this.core.ingameStatus == IngameStatus.PLAYING && this.markerSpellType != -1)
            {
				if (this.markerSpellType <= 2)
				{
					this.casters[this.markerSpellType] = new SpellCaster(GV.main.mouseX - 50, GV.main.mouseY - 8, this.markerSpellType);
					GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20), "Added a new marker!", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 1000);
					
				    this.spellImages[markerSpellType].circle.width = this.spellImages[markerSpellType].circle.height = spellRangeCircleSizes[markerSpellType].g() * 2 * 28;
					this.spellImages[markerSpellType].circle.x = GV.main.mouseX - 50;
					this.spellImages[markerSpellType].circle.y = GV.main.mouseY - 8;
					this.spellImages[markerSpellType].circle.visible = true;
				}
				else
				{
					var building:Object = SpellCaster.getBuildingForPos(GV.main.mouseX - 50, GV.main.mouseY - 8);
					if (building != null && (building is Tower || building is Lantern || building is Amplifier || building is Trap))
					{
						this.casters[this.markerSpellType] = new SpellCaster(GV.main.mouseX - 50, GV.main.mouseY - 8, this.markerSpellType);
						GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20), "Spell bound to building!", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 1000);
						
						this.spellImages[markerSpellType].x = GV.main.mouseX - iconBitmaps[markerSpellType - 3].width / 2;
						this.spellImages[markerSpellType].y = GV.main.mouseY - iconBitmaps[markerSpellType - 3].height / 2;
						this.spellImages[markerSpellType].visible = true;
					}
				}
				this.markerSpellType = -1;
			}
		}
		
		public function eh_ingameRightClickOnScene(e:IngameRightClickOnSceneEvent): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if(this.core.ingameStatus == IngameStatus.PLAYING && this.markerSpellType != -1)
            {
				this.casters[this.markerSpellType] = null;
				if (this.markerSpellType <= 2)
				{
					GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20), "Removed a marker!", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 1000);
					this.spellImages[markerSpellType].circle.visible = false;
				}
				else
				{
					GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Unbound spell from building!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
					this.spellImages[markerSpellType].visible = false;
				}
			}
			this.markerSpellType = -1;
		}
		
		public function onLevelStart(e:IngameNewSceneEvent): void
		{
			addImages();
		}
		
		public function eh_ingamePreRenderInfoPanel(e:IngamePreRenderInfoPanelEvent): void
		{	
			this.frameCounter++;
			if (this.frameCounter >= 15)
				this.castAtAllMarkers();
				
			for (var i:int = 0; i < this.casters.length; i++)
			{
				if (this.casters[i] != null && this.casters[i].valid())
				{
					this.spellImages[i].visible = true;
				}
				else
				{
					this.spellImages[i].visible = false;
				}
			}
		}
		
		private function castAtAllMarkers(): void
		{
			for each (var caster:SpellCaster in this.casters) 
			{
				if (caster != null && caster.valid() && caster.castReady())
				{
					caster.cast();
				}
			}
		}
		
		private function addImages(): void
		{
			for (var i:int = 0; i < 6; i++)
			{
				this.cnt.cntRetinaHud.addChild(this.spellImages[i]);
			}
		}
	}
}
