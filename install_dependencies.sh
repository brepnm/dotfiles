sudo apt install fzf
sudo apt install neovim
sudo apt install eza
sudo apt install bat

echo -e "{}" > ~/.shortcuts.json
# fill the json with default values
$default_shortcuts='{
    "default": "/",
    "var": "/var",
    "etc": "/etc",
    "nginx": "/etc/nginx",
    "www": "/var/www"
}'

echo -e $default_shortcuts > ~/.shortcuts.json