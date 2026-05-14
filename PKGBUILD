# Maintainer: GoldLego <goldlegomain@gmail.com>

pkgname=omarchy-gpu-menu
pkgver=0.0.1
pkgrel=1
pkgdesc="A visually appealing, Wofi-based GPU mode switcher for supergfxctl built for Omarchy"
arch=('any')
url="https://github.com/goldlego/omarchy-gpu-menu"
license=('MIT')

depends=('bash' 'wofi' 'supergfxctl' 'libnotify')

# Assuming the GitHub repo is named 'omarchy-gpu-menu' in all lowercase
source=("$pkgname-$pkgver.tar.gz::https://github.com/goldlego/$pkgname/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('7d8ffab0c58bd5bb6bc9d1a7a1bcb9819de0053136d7653ced02fe6191f7d1cd')

package() {
    cd "$pkgname-$pkgver"

    # Install the main bash script
    install -Dm755 omarchy-gpu-menu.sh "$pkgdir/usr/bin/omarchy-gpu-menu"

    # Install the Wofi configs
    install -Dm644 config/gpu-menu.conf "$pkgdir/etc/omarchy/wofi/gpu-menu.conf"
    install -Dm644 config/gpu-style.css "$pkgdir/etc/omarchy/wofi/gpu-style.css"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
