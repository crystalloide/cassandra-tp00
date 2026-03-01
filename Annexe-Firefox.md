## WSL 2 : 
```bash
export GTK_USE_PORTAL=0
echo 'export GTK_USE_PORTAL=0' >> ~/.bashrc
source ~/.bashrc
```

#### Installation de Firefox avec Snap :
```bash
sudo snap install firefox
firefox http://192.168.100.151:8081/
```

#### Réinstallation de Firefox en cas de problème si précédemment installé avec Snap :
```bash
sudo snap remove firefox
sudo add-apt-repository ppa:mozillateam/ppa
sudo apt update
sudo apt install firefox
```
