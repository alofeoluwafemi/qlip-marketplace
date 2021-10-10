const QLIPITMarketplace = artifacts.require('QLIPITMarketplace')
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
const ether = require('@openzeppelin/test-helpers/src/ether')
const { ethers } = require('ethers')

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract('QLIPITMarketplace', async function ([deployer, addressOne, addressTwo]) {
  let name, symbol, qlipContract

  before(async () => {
    name = 'Qlip NFT Marketplace'
    symbol = 'QLIP NFT'
    qlipContract = await QLIPITMarketplace.new(name, symbol)
  })

  it('should assert token name', async function () {
    const tokenName = await qlipContract.name()

    assert.equal(tokenName, name, "Token name doesn't match")
  })

  it('should assert token symbol', async function () {
    const tokenSymbol = await qlipContract.symbol()

    assert.equal(tokenSymbol, symbol, "Token name doesn't match")
  })

  it('should assert deployer is admin', async function () {
    const admin = await qlipContract.admin()

    assert.equal(deployer, admin, 'Deployer account is not admin')
  })

  it('should assert token Mint event', async function () {
    const _e = await qlipContract.mintWithIndex(deployer, 'https://token-url.com', 2)

    expectEvent(_e, 'Minted', {
      minter: deployer,
      tokenURI: 'https://token-url.com',
      // tokenId: 1,
    })
  })

  it('should assert deploy have a balance of 1 NFT', async function () {
    const tokenBalance = await qlipContract.balanceOf(deployer)

    const tokenBalanceBigNumber = ethers.utils.parseEther(tokenBalance.toString()) //Convert BN returned by EVM to BigNumber in Ethersjs to compare result

    assert.equal(true, tokenBalanceBigNumber.eq(ethers.utils.parseEther('1')), 'Address owns more than one NFT')
  })

  it('should assert deployer address returns an array of NFT with length of 1 and tokenId of 1 as the only item', async function () {
    const tokens = await qlipContract.getNftByAddress(deployer)

    assert.equal(1, tokens.length, "Address minted NFTs doesn't match")
  })

  it('should assert owned tokens doesnt consist of null value in array due to delete operation', async function () {
    await qlipContract.safeTransferFrom(deployer, addressOne, 1)
    const tokens = await qlipContract.getNftByAddress(deployer)

    assert.equal(0, tokens.length, "Address minted NFTs doesn't match")
  })
})
