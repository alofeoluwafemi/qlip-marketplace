const QLIPITMarketplace = artifacts.require('QLIPITMarketplace')

module.exports = function (deployer) {
  deployer.deploy(QLIPITMarketplace, 'Qlip NFT Marketplace', 'QLIP NFT')
}
