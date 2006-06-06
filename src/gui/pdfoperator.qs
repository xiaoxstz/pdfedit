/* === Validation functions === */


/** Is this operator text operator. */
function isTextOp(operator) {
	var txtit = operator.textIterator();
	if (!txtit.isEnd() && operator.equals(txtit.current()))
		return true;
	else
		return false;
}

/** Is this operator text operator. */
function isChangeableOp(operator) {
	var txtit = operator.changeableIterator();
	if (!txtit.isEnd() && operator.equals(txtit.current()))
		return true;
	else
		return false;
}

/* === Helper functions === */
function operatorInitChange(operator) {
	var prev = operator.iterator();
	prev.prev();
	var next = operator.getLastOperator().iterator();
	next.next();

	operator.setPrev( createEmptyOperator() );
	operator.getLastOperator().setNext( createEmptyOperator() );

	return [prev,next];
}


/* === Content stream helper functions === */
function putnscolor (op,r,g,b) {
	var operands = createIPropertyArray();
	operands.append(createReal(r/255));
	operands.append(createReal(g/255));
	operands.append(createReal(b/255));
	op.pushBack( createOperator(operands, "rg"),op.getLastOperator());
}
function putscolor (op,r,g,b) {
	var operands = createIPropertyArray();
	operands.append(createReal(r/255));
	operands.append(createReal(g/255));
	operands.append(createReal(b/255));
	op.pushBack( createOperator(operands, "RG"),op.getLastOperator());
}

function putfont (op,fid,fs) {
	var operands = createIPropertyArray ();
	operands.append(createName(fid));
	operands.append(createReal(fs));
	op.pushBack(createOperator(operands, "Tf"), op.getLastOperator());
}
function putline (op,lx,ly,rx,ry) {
	var operands = createIPropertyArray ();
	operands.append (createReal(lx));
	operands.append (createReal(ly));
	op.pushBack (createOperator(operands, "m"), op.getLastOperator());

	operands.clear();
	operands.append (createReal(rx));
	operands.append (createReal(ry));
	op.pushBack (createOperator(operands, "l"),op.getLastOperator());
}
function putrect (op,x,y,w,h) {
	var operands = createIPropertyArray ();
	operands.append (createReal(x));
	operands.append (createReal(y));
	operands.append (createReal(w));
	operands.append (createReal(h));
	op.pushBack (createOperator(operands, "re"),op.getLastOperator());
}
function putlinewidth (op,w) {
	var operands = createIPropertyArray ();
	operands.append (createInt(w));
	op.pushBack (createOperator(operands, "w"), op.getLastOperator());	
}
function puttextrelpos (op,dx,dy) {
	var operands = createIPropertyArray ();
	operands.append (createReal(dx));
	operands.append (createReal(dy));
	op.pushBack (createOperator(operands, "Td"), op.getLastOperator());
}
function putenddraw (op) {
	var operands = createIPropertyArray ();
	op.pushBack (createOperator(operands, "S"),op.getLastOperator());
}
function putendfill (op) {
	var operands = createIPropertyArray ();
	op.pushBack (createOperator(operands, "B"),op.getLastOperator());
}
function puttext (op,txt) {
	var operands = createIPropertyArray ();
	operands.append (createString(txt));
	op.pushBack (createOperator(operands, "Tj"),op.getLastOperator());
}
function putendtext (op) {
	var operands = createIPropertyArray ();
	op.pushBack (createOperator(operands, "ET"),op.getLastOperator());
}
function putendq (op) {
	var operands = createIPropertyArray ();
	op.pushBack( createOperator(operands, "Q"), op.getLastOperator());
}

/** == debug utilities == */
function _dbgprintOpersB() {
	
	op=treeitem.item();
	var it = op.iterator();
	while (it.valid()) {
		print (it.current().getName());
		it.prev();
	}
}

/** == debug utilities == */
function _dbgprintOpers() {
	
	op=treeitem.item();
	var it = op.iterator();
	while (!it.isEnd()) {
		print (it.current().getName());
		it.next();
	}
}

/** set color of operator
 * @param operator change color of this operator
 * @param r red component of color for set
 * @param g green component of color for set
 * @param b blue component of color for set
 *
 * If red,green or blue component is not set, view color dialog for set correct color.
 */
function operatorSetColor(operator,r,g,b) {
	// --------  check parameters  ---------

	if (operator.type() != "PdfOperator") {
		warn( tr("Operator must be QSPdfOperator !!!") );
		return ;
	}
	if ((r == undefined) || (g == undefined) || (b == undefined)) {
		var col = pickColor();
		if (isNaN(col)) {
			warn( tr("Must define color !!!") );
			return operator;
		}
		r=col.red;
		g=col.green;
		b=col.blue;
	}
	if (((typeof r ) != "number") ||
		((typeof g ) != "number") ||
		((typeof b ) != "number")) {
		warn( tr("r,g,b must be number !!!") );
		return operator;
	}
	if (((r<0) || (r>255)) ||
		((g<0) || (g>255)) ||
		((b<0) || (b>255))) {
		warn( tr("r,g,b must be from 0 to 255 !!!") );
		return operator;
	}

	// --------  set color of operator  ---------

	var posit = operatorInitChange(operator);

	//
	// Create 
	//  q
	//  r g b rg/RG
	//  oper
	//  Q
	//
	var composite = createCompositeOperator("q","Q");


	var cntNon = operator.containsNonStrokingOperator();
	var cntStr = operator.containsStrokingOperator();

	// E.g if text found put rg, if lin put RG, can be both
	if (cntNon) {
		putnscolor (composite,r,g,b,composite);
	}
	if (cntStr) {
		putscolor (composite,r,g,b);
	} 
	
	// It the operator does not contain any known operators put them both
	if (!cntNon && !cntStr)	{
		putnscolor (composite,r,g,b);
		putscolor (composite,r,g,b);
	}

	composite.pushBack( operator );
	putendq(composite);

	operator.stream().replace(operator, composite, posit[0], posit[1]);
}

/** 
 * Get font and font size of a text operator.
 * We have to find preceding Font operator.
 *
 * @param operator Pdf operator.
 */
function operatorGetFont(operator) {
	
	// === Check parameters  ===

	if ("PdfOperator" != operator.type()) {
		warn (tr("Operator must be")+" QSPdfOperator !!!");
		return;
	}

	// ===  Get the preceding font operator ===  

	//  Traverse it backwards 
	var fontoper = operator.fontIterator(false).current();
	if (undefined == fontoper) {
		warn (tr("No preceding font operator found..."));
		return;
	}
		
	var firstoper = fontoper.params().property(0);
	var secondoper = fontoper.params().property(1);
	if ('IProperty' != firstoper.type() || 'IProperty' != secondoper.type()) {
		print (firstoper.type());
		warn (tr("Invalid operand type"));
		return;
	}
	var fonttype = firstoper.value();
	var fontsize = secondoper.getText();
	return [fonttype, fontsize];
}

/** 
 * Set font and font size of a text operator.
 * We have to find preceding Font operator.
 *
 * @param operator Pdf operator.
 * @param fontid Font id of the new font. Not the font name.
 * @param fontsize Font size, but this can vary from normal pixel size.
 */
function operatorSetFont(operator, fontid, fontsize) {

	// == Check type

	if ("PdfOperator" != operator.type()) {
		warn( tr("Operator must be") + " QSPdfOperator !!!");
		return;
	}

	// == Set new font around this operator

	var posit = operatorInitChange (operator);

	//
	// q 
	// fontid fontsize Tf
	// oper
	// Q
	//
	var composite = createCompositeOperator ("q","Q");

	putfont(composite,fontid,fontsize);

    /* Put the changed operator also in the queue */
	composite.pushBack (operator);
	putendq(composite);

	// replace it
	operator.stream().replace (operator, composite, posit[0], posit[1]);
}

/** 
 * Set linewidth of an operator.
 *
 * @param operator Pdf operator.
 * @param Width of a line. 0 means tiniest.
 * @param globchange If true change is global.
 */
function operatorSetLineWidth(operator, linewidth, globchange) {

	// == Check type

	if ("PdfOperator" != operator.type()) {
		warn( tr("Operator must be") + " QSPdfOperator !!!");
		return;
	}

	// == Set new font around this operator

	var posit = operatorInitChange (operator);
	
	//
	// q
	// linewidth w
	// oper
	// Q
	//
	if (globchange) {
		composite = createCompositeOperator ("","");
	}else {
		composite = createCompositeOperator ("q","Q");
	}

	putlinewidth (composite,linewidth);

    /* Put the changed operator also in the queue */
	composite.pushBack (operator);

	operands.clear();
	if (!globchange)
		putendq(composite);

	operator.stream().replace (operator, composite, posit[0], posit[1]);
}

/** 
 * Set simple dash pattern from provided alternatives.
 *
 * @param alt Dash style.
 * @param operator Operator.
 * @param globchange If true changes will be global, if false only selected operator will be changed.
 */
function operatorSetSimpleDashPattern(alt,operator,globchange) {
	var array = [];
	var step = 600;
 	switch(alt) {
	case 0 :
		break;
	case 1 :
		array = [3];
		break;
	case 2 :
		array = [2,1];
		break;
	default:
		warn (tr("This option is not supported."));
		return false;
	}
	operatorSetDashPattern(operator,array,0,globchange);
	return true;
 }

/** 
 * Set dash pattern of an operator.
 *
 * @param operator Pdf operator.
 * @param array The dash array's elements are numbers that specify the lengths of alternating dashes and gaps.
 * @param phase The dash phase specifies the distance into the dash pattern at which to start the dash.
 * @param globchange If true changes will be global, if false only selected operator will be changed.
 */
function operatorSetDashPattern(operator, array, phase, globchange) {

	// == Check type

	if ("PdfOperator" != operator.type()) {
		warn( tr("Operator must be") + " QSPdfOperator !!!");
		return;
	}

	// == Set new font around this operator

	var posit = operatorInitChange(operator);
	
	//
	// q
	// array phase d
	// oper
	// Q
	//
	if (globchange) {
		composite = createCompositeOperator("","");
	}else {
		composite = createCompositeOperator("q","Q");
	}

	var operands = createIPropertyArray ();
	var iparray = createArray();
	for (i=0; i<array.length; ++i)
		iparray.add(i,createInt(array[i]));
	operands.append (iparray);
	operands.append (createInt(phase));
	composite.pushBack (createOperator(operands, "d"), composite);

    /* Put the changed operator also in the queue */
	composite.pushBack (operator);

	operands.clear();
	if (!globchange)
		putendq (composite);

	operator.stream().replace (operator, composite, posit[0], posit[1]);
}



/** === Font utilities === */

/**
 * Get all system fonts from pdf specification v 1.5.
 * Every viewer should have default metrics for these fonts avaliable.
 */ 
function getSystemFonts() {
 return ["Times-Roman", "Helvetica", "Courier",
 		 "Symbol", "Times-Bold", "Helvetica-Bold",
		 "Courier-Bold", "ZapfDingbats", "Times-Italic",
		 "Helvetica-Oblique", "Courier-Oblique", 
		 "Times-BoldItalic", "Helvetica-BoldOblique", 
		 "Courier-BoldOblique"];
}

/**
 * Edit position of a text positioning operator.
 */
function operatorMovePosition(operator, dx, dy) {

	var pars = operator.params();
	var x = parseFloat (pars.property(0).value());
	var y = parseFloat (pars.property(1).value());
	pars.property(0).set(x + dx);
	pars.property(1).set(y + dy);
}

/**
 * Edit position of a text positioning operator.
 */
function operatorSetPosition(operator, dx, dy) {

	// == Set new operator position

	var posit = operatorInitChange(operator);
	
	//
	// q
	// array phase d
	// oper
	// Q
	//
	var composite = createCompositeOperator("q","Q");

	puttextrelpos(composite,dx,dy);

    /* Put the changed operator also in the queue */
	composite.pushBack (operator);

	puttextrelpos (composite,-dx,-dy)
	putendq(composite);

	operator.stream().replace (operator, composite, posit[0], posit[1]);

}


/**
 * Get nearest text position operator and its x, y values
 */
function getPosInfoOfOperator (operator) {
	
	var txtit = operator.iterator();
	while (!txtit.isBegin()) {
		print (txtit.current().getName());
		if ("TD" == txtit.current().getName() || 
				"Td" == txtit.current().getName())
			return txtit.current();
		txtit.prev();
	}

	return undefined;
}

/**
 * Draw line from start position to end position.
 */
function operatorDrawLine (lx,ly,rx,ry,width,col) {
	//
	// q
	// array phase d
	// oper
	// Q
	//
	var composite = createCompositeOperator("q","Q");

	if (undefined != width) {
		putlinewidth (composite,width);
	}

	if (undefined != col) {
		putscolor(composite,col.red,col.green,col.blue);
	}
	
	putline (composite,lx,ly,rx,ry)
	putenddraw (composite);

	putendq(composite,composite);

	var ops = createPdfOperatorStack();
	ops.append (composite);
	page().addContentStream(ops);
}

/**
 * Draw rectangle specyfing left upper corner, width and height.
 */
function operatorDrawRect (lx,ly,width,height,col) {
	
	//
	// q
	// array phase d
	// oper
	// Q
	//
	var composite = createCompositeOperator("q","Q");

	if (undefined != col) {
		putscolor(composite,col.red,col.green,col.blue);
		putnscolor(composite,col.red,col.green,col.blue);
	}

	putrect (composite,lx,ly,width,height);
	putendfill (composite);
	putenddraw (composite);
	putendq(composite,composite);

	var ops = createPdfOperatorStack();
	ops.append (composite);
	page().addContentStream(ops);
}

/**
 * Add text line.
 */
function operatorAddTextLine (text,x,y,fname,fsize) {
	//
	// q
	// BT
	// fname fsize Tf
	// x y Td
	// text Tj
	// ET
	// Q
	//
	var q = createCompositeOperator("q","Q");
	var BT = createCompositeOperator("BT","ET");
	
	q.pushBack (BT,q);
	
	putfont(BT,fname,fsize);
	puttextrelpos (BT,x,y);
	puttext (BT,text);
	putendtext (BT);
	putendq(q);

	var ops = createPdfOperatorStack();
	ops.append (q);
	page().addContentStream(ops);
}

