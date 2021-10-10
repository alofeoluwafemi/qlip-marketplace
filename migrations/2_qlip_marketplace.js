const QlipMarketPlace = artifacts.require('QlipMarketPlace')

module.exports = function (deployer) {
  deployer.deploy(QlipMarketPlace, 'Qlip NFT Marketplace', 'QLIP NFT')
}
