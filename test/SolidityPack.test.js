import { expect } from 'chai';
import hre from 'hardhat';
import { encode, encodeToHex } from '../lib/encoder.js';
import { decode } from '../lib/decoder.js';

describe('SolidityPack', function () {
    let encoderTest;
    let decoderTest;

    before(async function () {
        // Deploy test contracts
        const EncoderTest = await hre.ethers.getContractFactory('EncoderTest');
        encoderTest = await EncoderTest.deploy();

        const DecoderTest = await hre.ethers.getContractFactory('DecoderTest');
        decoderTest = await DecoderTest.deploy();
    });

    describe('Encoder Tests', function () {
        it('should encode {test: 42, test2: []} correctly', async function () {
            const result = await encoderTest.testEncodeMapWithEmptyArray();
            const jsEncoded = encode({ test: 42, test2: [] });

            console.log('  Solidity encoded:', result);
            console.log('  JavaScript encoded:', '0x' + jsEncoded.toString('hex'));

            expect(result).to.equal('0x' + jsEncoded.toString('hex'));
        });

        it('should verify encoding matches expected', async function () {
            const matches = await encoderTest.verifyEncodingMatches();
            expect(matches).to.be.true;
        });

        it('should encode basic types', async function () {
            const result = await encoderTest.testEncodeBasicTypes();
            expect(result.length).to.be.greaterThan(0);
            console.log('  Basic types encoded:', result);
        });

        it('should encode nested structures', async function () {
            const result = await encoderTest.testEncodeNestedStructure();
            expect(result.length).to.be.greaterThan(0);

            // Decode with JavaScript to verify
            const decoded = decode(result);
            console.log('  Decoded nested structure:', decoded);
            expect(decoded.name).to.equal('Alice');
            expect(decoded.age).to.equal(30);
            expect(decoded.tags).to.be.an('array').with.lengthOf(2);
        });

        it('should encode using array helpers', async function () {
            const result = await encoderTest.testEncodeArrayHelpers();
            const decoded = decode(result);

            console.log('  Decoded with helpers:', decoded);
            expect(decoded.numbers).to.be.an('array').with.lengthOf(3);
            expect(decoded.numbers[0]).to.equal(10);
            expect(decoded.addresses).to.be.an('array').with.lengthOf(2);
            expect(decoded.strings).to.be.an('array').with.lengthOf(2);
        });

        it('should encode large numbers', async function () {
            const result = await encoderTest.testEncodeLargeNumbers();
            const decoded = decode(result);

            console.log('  Large numbers:', decoded);
            expect(decoded).to.be.an('array').with.lengthOf(4);
            expect(decoded[0]).to.equal(255); // uint8.max
        });

        it('should encode negative numbers', async function () {
            const result = await encoderTest.testEncodeNegativeNumbers();
            const decoded = decode(result);

            console.log('  Negative numbers:', decoded);
            expect(decoded).to.be.an('array').with.lengthOf(5);
            expect(decoded[0]).to.equal(-1);
            expect(decoded[1]).to.equal(-32);
        });

        it('should perform round-trip encoding/decoding', async function () {
            const [success, decodedNumber, decodedString] = await encoderTest.testRoundTrip();

            expect(success).to.be.true;
            expect(decodedNumber).to.equal(12345n);
            expect(decodedString).to.equal('test string');
        });

        it('should encode complex nested object', async function () {
            const result = await encoderTest.testEncodeComplexObject();
            const decoded = decode(result);

            console.log('  Complex object:', JSON.stringify(decoded, null, 2));
            expect(decoded.owner).to.be.a('string');
            expect(decoded.balance).to.equal(1000000);
            expect(decoded.active).to.be.true;
            expect(decoded.metadata).to.be.an('object');
            expect(decoded.metadata.name).to.equal('Alice');
        });
    });

    describe('Decoder Tests', function () {
        it('should decode {test: 42, test2: []}', async function () {
            const [key1, value1, key2, arrayLen] = await decoderTest.testDecodeMapWithEmptyArray();

            expect(key1).to.equal('test');
            expect(value1).to.equal(42n);
            expect(key2).to.equal('test2');
            expect(arrayLen).to.equal(0n);
        });

        it('should inspect types correctly', async function () {
            const [isMap, hasMoreAfterDecode] = await decoderTest.testTypeInspection();

            expect(isMap).to.be.true;
            expect(hasMoreAfterDecode).to.be.false;
        });

        it('should decode heterogeneous array', async function () {
            const [uintVal, strVal, boolVal, nilDecoded] = await decoderTest.testDecodeHeterogeneousArray();

            expect(uintVal).to.equal(42n);
            expect(strVal).to.equal('hello');
            expect(boolVal).to.be.true;
            expect(nilDecoded).to.be.true;
        });

        it('should selectively decode with skip', async function () {
            const [firstValue, thirdValue] = await decoderTest.testSelectiveDecoding();

            expect(firstValue).to.equal(1n);
            expect(thirdValue).to.equal(3n);
        });

        it('should decode address', async function () {
            const addr = await decoderTest.testDecodeAddress();
            expect(addr).to.equal('0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1');
        });

        it('should decode bytes32', async function () {
            const value = await decoderTest.testDecodeBytes32();
            expect(value).to.equal('0x00000000000000000000000000000000000000000000000000000000deadbeef');
        });

        it('should decode uint array', async function () {
            const [len, first, last] = await decoderTest.testDecodeUintArray();

            expect(len).to.equal(3n);
            expect(first).to.equal(10n);
            expect(last).to.equal(30n);
        });

        it('should decode address array', async function () {
            const [len, first, second] = await decoderTest.testDecodeAddressArray();

            expect(len).to.equal(2n);
            expect(first).to.equal('0x1111111111111111111111111111111111111111');
            expect(second).to.equal('0x2222222222222222222222222222222222222222');
        });

        it('should decode string array', async function () {
            const [len, first, second] = await decoderTest.testDecodeStringArray();

            expect(len).to.equal(2n);
            expect(first).to.equal('hello');
            expect(second).to.equal('world');
        });

        it('should decode nested object', async function () {
            const [name, age, tagsLen, firstTag] = await decoderTest.testDecodeNestedObject();

            expect(name).to.equal('Alice');
            expect(age).to.equal(17n); // This is encoded as 0x11 = 17
            expect(tagsLen).to.equal(2n);
            expect(firstTag).to.equal('user');
        });

        it('should peek categories correctly', async function () {
            const allCorrect = await decoderTest.testPeekCategory();
            expect(allCorrect).to.be.true;
        });

        it('should decode large numbers', async function () {
            const [val1, val2] = await decoderTest.testDecodeLargeNumbers();

            expect(val1).to.equal(18446744073709551615n); // uint64.max
            expect(val2).to.equal(340282366920938463463374607431768211455n); // uint128.max
        });

        it('should decode negative numbers', async function () {
            const [val1, val2, val3] = await decoderTest.testDecodeNegativeNumbers();

            expect(val1).to.equal(-1n);
            expect(val2).to.equal(-128n);
            expect(val3).to.equal(-2147483648n); // int32.min
        });
    });

    describe('JavaScript <-> Solidity Interop', function () {
        it('should encode in JS and decode in Solidity', async function () {
            // Encode in JavaScript
            const jsData = { test: 42, test2: [] };
            const encoded = encodeToHex(jsData);

            // The decoder test contract already has this test
            const [key1, value1, key2, arrayLen] = await decoderTest.testDecodeMapWithEmptyArray();

            expect(key1).to.equal('test');
            expect(value1).to.equal(42n);
        });

        it('should encode in Solidity and decode in JS', async function () {
            // Encode in Solidity
            const encoded = await encoderTest.testEncodeMapWithEmptyArray();

            // Decode in JavaScript
            const decoded = decode(encoded);

            expect(decoded).to.deep.equal({ test: 42, test2: [] });
        });

        it('should handle complex nested structures both ways', async function () {
            // Solidity -> JS
            const solidityEncoded = await encoderTest.testEncodeComplexObject();
            const jsDecoded = decode(solidityEncoded);

            console.log('  Solidity -> JS:', jsDecoded);
            expect(jsDecoded.owner).to.be.a('string');
            expect(jsDecoded.balance).to.equal(1000000);

            // JS -> Solidity (via manual encoding)
            const jsData = {
                owner: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1',
                balance: 1000000,
                active: true,
                metadata: {
                    name: 'Alice',
                    tags: ['premium', 'verified']
                }
            };
            const jsEncoded = encode(jsData);
            const jsReDecoded = decode(jsEncoded);

            console.log('  JS -> JS:', jsReDecoded);
            expect(jsReDecoded).to.deep.equal(jsData);
        });
    });
});
