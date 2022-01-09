const BigNumber = require('bignumber.js')
const truffleAssert = require('truffle-assertions');

const TIME_UNIT = {
    DAY: 86400,
    WEEK: 604800,
    MONTH: 2592000,
};


function toHex(d, padding=2) {
    var hex = Number(d).toString(16);
    while (hex.length < padding) hex = "0" + hex;
    if (hex.length > padding) hex = hex.substr(hex.length - padding);
    return hex;
}

const buildBondBytes = ({flag, currencyRef, nPeriods, curPeriod, claimedPeriods, startTime, periodDuration, couponSize, faceValue, minter}) => {
    s = {};
    s.flag = flag ? '01' : '00';
    s.currencyRef = toHex(currencyRef || 0, 6);
    s.nPeriods = toHex(nPeriods || 0, 4);
    s.curPeriod = toHex(curPeriod || 0, 4);
    s.claimedPeriods = toHex(claimedPeriods || 0, 4);
    s.startTime = toHex(startTime || 0, 12);
    s.periodDuration = toHex(periodDuration || 0, 4); // not how it works in the contract
    s.couponSize = toHex(~~couponSize || 0, 8); // not how it works in the contract
    s.faceValue = toHex(~~faceValue || 0, 8);
    // s.beneficiary = beneficiary.substring(2);
    s.minter = minter.substring(2);
    const a = `0x${s.flag}${s.couponSize}${s.nPeriods}${s.curPeriod}${s.currencyRef}${s.claimedPeriods}`.padEnd(64, '0').toLowerCase();
    const b = `0x${s.faceValue}${s.startTime}${s.periodDuration}${s.minter}`.padEnd(64, '0').toLowerCase();
    return [a, b];
}



const getAllSimpleStorage = async (addr, offset=0) => {
    let slot = offset
    let zeroCounter = 0
    const simpleStorage = []
    // eslint-disable-next-line no-constant-condition
    while (true) {
        const data = await web3.eth.getStorageAt(addr, slot)
        if (new BigNumber(data).eq(0)) {
        zeroCounter++
        }

        simpleStorage.push({ slot, data })
        slot++

        if (zeroCounter > 10) {
        break
        }
    }

    return simpleStorage.splice(0, simpleStorage.length - 11);
}

function now() {
    return Math.floor(Date.now() / 1000);
}

function getEvent(tx, event) {
    return new Promise((resolve, reject) => {
        truffleAssert.eventEmitted(tx, event, resolve);
        reject(`No event ${event} emitted`);
    });
}

async function getEvents(tx, event) {
    return tx.logs
        .filter(l => l.event == event)
        .map(l => l.args);
}

function getRevert(prom, m) {
    return new Promise((resolve, reject) => {
        prom
            .catch(resolve)
            .then(() => assert.exists(null, m || "Expected revert but no error thrown"))
            .catch(reject);
    });
}

function increaseTime(duration) {
    const id = Date.now();
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [duration],
            id: id,
        }, err1 => {
            if (err1) return reject(err1)
        
            web3.currentProvider.send({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: id+1,
            }, (err2, res) => {
                return err2 ? reject(err2) : resolve(res)
            });
        })
    });
}

async function callAndGetReturn(action, ...args) {
    let val = await action.call(...args);
    await action(...args);
    return val;
}

module.exports = { getAllSimpleStorage, buildBondBytes, getEvent, getEvents, getRevert, increaseTime, now, TIME_UNIT };