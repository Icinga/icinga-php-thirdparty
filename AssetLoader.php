<?php

class AssetLoader
{
    public static function update(Composer\Script\Event $event)
    {
        if (! is_dir('asset/js/jquery')) {
            mkdir('asset/js/jquery', 0775, true);
        }

        copy('vendor/components/jquery/jquery.js', 'asset/js/jquery/jquery.js');
        copy('vendor/components/jquery/jquery.min.js', 'asset/js/jquery/jquery.min.js');
    }
}
