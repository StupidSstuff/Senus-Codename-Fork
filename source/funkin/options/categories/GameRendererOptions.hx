package funkin.options.categories;

import funkin.options.Options;

class GameRendererOptions extends TreeMenuScreen
{
	public function new()
	{
		super('optionsTree.gameRenderer-name', 'optionsTree.gameRenderer-desc', 'GameRendererOptions.');

		add(new Checkbox(getNameID('ffmpegMode'), getDescID('ffmpegMode'), 'ffmpegMode'));
		add(new NumOption(getNameID('targetFPS'), getDescID('targetFPS'), 1, 240, 1, 'targetFPS'));
		add(new Checkbox(getNameID('unlockFPS'), getDescID('unlockFPS'), 'unlockFPS'));
		add(new NumOption(getNameID('renderBitrate'), getDescID('renderBitrate'), 1, 100, 0.5, 'renderBitrate'));

		add(new ArrayOption(
			getNameID('vidEncoder'),
			getDescID('vidEncoder'),
			['libx264', 'libx264rgb', 'libx265', 'libxvid', 'libsvtav1', 'mpeg2video'],
			['libx264', 'libx264rgb', 'libx265', 'libxvid', 'libsvtav1', 'mpeg2video'],
			'vidEncoder'
		));

		add(new Checkbox(getNameID('oldFFmpegMode'), getDescID('oldFFmpegMode'), 'oldFFmpegMode'));
		add(new Checkbox(getNameID('lossless'), getDescID('lossless'), 'lossless'));
		add(new NumOption(getNameID('quality'), getDescID('quality'), 1, 100, 1, 'quality'));
		add(new NumOption(getNameID('renderGCRate'), getDescID('renderGCRate'), 0, 60, 0.1, 'renderGCRate'));
		add(new TextOption(getNameID('openRenderFolder'), getDescID('openRenderFolder'), ' >', __openRenderFolder));
	}

	private function __openRenderFolder()
	{
		#if windows
			Sys.command('explorer', [StringTools.replace(Options.renderPath, '/', '\\')]);
		#elseif linux
			Sys.command('xdg-open', [Options.renderPath]);
		#elseif mac
			Sys.command('open', [Options.renderPath]);
		#else
			trace('Opening the render folder is unavailable on this target.');
		#end
	}
}
