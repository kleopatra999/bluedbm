//import XilinxVC707DDR3::*;
import FIFO::*;
import Vector::*;
import BRAM::*;

typedef 16 WordBytes;
typedef TMul#(8,WordBytes) WordSz;
typedef 8192 PageBytes;
typedef TDiv#(PageBytes,WordBytes) PageWords;
typedef TLog#(PageWords) PageWordsLog;

interface PageCacheIfc#(numeric type tBufferSizeLog);
	method Action readPage(Bit#(64) pageIdx, Bit#(8) tag);
	method ActionValue#(Tuple2#(Bit#(WordSz), Bit#(8))) readWord;
	method Action writePage (Bit#(64) pageIdx, Bit#(8) tag);
	method Action writeWord (Bit#(WordSz) data, Bit#(8) tag);
endinterface

module mkPageCache (PageCacheIfc#(tBufferSizeLog))
provisos ( Add#(a__, TAdd#(PageWordsLog, tBufferSizeLog), 64),Add#(b__, tBufferSizeLog, 64));
	BRAM2Port#(Bit#(TAdd#(PageWordsLog,tBufferSizeLog)), Bit#(WordSz)) pageBuffer <- mkBRAM2Server(defaultValue); // 8k pages 

	Integer wordBytes = valueOf(WordBytes);
	Integer wordSz = valueOf(WordSz);
	Integer pageBytes = valueOf(PageBytes);
	Integer pageWords = valueOf(PageWords);
	Integer pageWordsLog = valueOf(PageWordsLog);

	Reg#(Bit#(64)) curReadIdx <- mkReg(0);
	Reg#(Bit#(8)) curReadTag <- mkReg(0);
	Reg#(Bit#(32)) readCount <- mkReg(99999999);
	
	//Reg#(Bit#(64)) curWriteIdx <- mkReg(0);
	Vector#(64, Reg#(Tuple2#(Bit#(tBufferSizeLog), Bit#(32)))) writeIdx <- replicateM(mkReg(tuple2(0, 99999)));
	Reg#(Bit#(8)) curWriteTag <- mkReg(0);
	Reg#(Bit#(32)) writeCount <- mkReg(99999999);

	Reg#(Bit#(64)) globalCounter <- mkReg(0);
	FIFO#(Bit#(8)) readTagQ <- mkSizedFIFO(8);

	rule driveReadReq( readCount < fromInteger(pageWords) );
		Bit#(tBufferSizeLog) bufidx = truncate(curReadIdx);
		Bit#(64) addroff = extend(bufidx)<<pageWordsLog;
		Bit#(64) exreadCount = extend(readCount);
		
		pageBuffer.portB.request.put(
			BRAMRequest{
				write:False, 
				responseOnWrite:?, 
				address:truncate(addroff+exreadCount), 
				datain:?});
		readCount <= readCount + 1;
		readTagQ.enq(curReadTag);
	endrule
	FIFO#(Bit#(WordSz)) readDataQ <- mkFIFO;
	rule recvReadResp;
		let v <- pageBuffer.portB.response.get();
		readDataQ.enq(v);
	endrule

	FIFO#(Bool) fakeQ_wp <- mkFIFO();
	FIFO#(Tuple2#(Bit#(64), Bit#(8))) writePageQ <- mkFIFO();
	rule driveWritePage ( tpl_2(writeIdx[tpl_2(writePageQ.first)]) >= fromInteger(pageWords) );
		writePageQ.deq;
		let tag = tpl_2(writePageQ.first);
		let idx = tpl_1(writePageQ.first);

		writeIdx[tag] <= tuple2(truncate(idx), 0);
	endrule
	
	method Action readPage (Bit#(64) pageIdx, Bit#(8) tag) if ( readCount >= fromInteger(pageWords) );
		curReadTag <= tag;
		Bit#(tBufferSizeLog) pageIdxt = truncate(pageIdx);
		curReadIdx <= zeroExtend(pageIdxt);
		readCount <= 0;
	endmethod
	method ActionValue#(Tuple2#(Bit#(WordSz), Bit#(8))) readWord;
		//let v <- pageBuffer.portB.response.get();
		let v = readDataQ.first;
		readDataQ.deq;
		//readCount <= readCount - 8;
		globalCounter <= globalCounter + 1;
		readTagQ.deq;
		return tuple2(v, readTagQ.first);
	endmethod
	
	method Action writePage (Bit#(64) pageIdx, Bit#(8) tag);
		writePageQ.enq(tuple2(pageIdx, tag));
		//if ( tpl_2(writeIdx[tag]) < 4096/8) fakeQ_wp.deq;

		//writeIdx[tag] <= tuple2(truncate(pageIdx), 0);
	endmethod
	method Action writeWord (Bit#(WordSz) data, Bit#(8) tag);
		let wi = writeIdx[tag];
		let idx = tpl_1(wi);
		Bit#(64) offset = extend(tpl_2(wi));
		Bit#(64) idxoff = extend(idx)<<pageWordsLog;

		writeIdx[tag] <= tuple2(tpl_1(wi), tpl_2(wi) + 1);
		
		if ( tpl_2(wi) < fromInteger(pageWords) ) begin
			pageBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(offset+idxoff), datain:data});
		end else begin
			fakeQ_wp.deq;
		end
	endmethod
endmodule
