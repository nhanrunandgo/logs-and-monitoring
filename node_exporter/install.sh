sudo mkdir -p /opt/custom_metrics
sudo cp rockchip_metrics.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/rockchip_metrics.sh

sudo cp rockchip-metrics.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rockchip-metrics.service
sudo systemctl start rockchip-metrics.service