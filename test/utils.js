const BigNumber = require('bignumber.js')
const truffleAssert = require('truffle-assertions');

const TIME_UNIT = {
    DAY: 86400,
    WEEK: 604800,
    MONTH: 2592000,
};


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

module.exports = { getAllSimpleStorage, getEvent, getEvents, getRevert, increaseTime, now, TIME_UNIT };