/** @file
 PageTool - Toolbutton showing current page number and allowing to change it
 @author Martin Petricek
*/

#include <utils/debug.h>
#include "pagetool.h"
#include <qfont.h>
#include <qstring.h>
#include <qlineedit.h>
#include <qvalidator.h>
#include "settings.h"

namespace gui {

/**
 Default constructor of PageTool
 @param parent Toolbar containing this control
 @param name Name of this widget (passed to QWidget constructor)
*/
PageTool::PageTool(QWidget *parent/*=0*/,const char *name/*=NULL*/) : QWidget (parent,name) {
 pageNum=new QLineEdit("    0",this,"page_select");
 ival=new QIntValidator(this);
 ival->setBottom(1);
 pageNum->setAlignment(Qt::AlignHCenter);
 pageNum->setValidator(ival);
 QObject::connect(pageNum,SIGNAL(returnPressed()),this,SLOT(selectPage()));
 QObject::connect(pageNum,SIGNAL(lostFocus()),this,SLOT(selectPage()));
}

/** default destructor */
PageTool::~PageTool() {
 delete pageNum;
 delete ival;
}


/**
 return size hint of this control (with widht for approx 4 characters)
 @return size hint
*/
QSize PageTool::sizeHint() const {
 QFont font=pageNum->font();
 QFontMetrics fm(font);
 QSize ps=pageNum->sizeHint();
 //Enough space for approx. 4 characters
 ps.setWidth(fm.width("0")*5);
 return ps;
}

/**
 Called on resizing of property editing control
 Will simply set the same fixed size to inner page editbox
 @param e resize event
*/
void PageTool::resizeEvent (QResizeEvent *e) {
 pageNum->setFixedSize(e->size());
}

/**
 Called on setting new page from this control
*/
void PageTool::selectPage() {
 selectPage(pageNum->text());
}

/**
 Called on setting new page from this control
 @param newPage
*/
void PageTool::selectPage(const QString &newPage) {
 QString thePage=newPage.stripWhiteSpace();
 thePage=thePage.section(' ',0);
 curPage=thePage.toInt();
 guiPrintDbg(debug::DBG_DBG,"Page set: " << curPage);
 if (curPage<1) return;
 updatePage();
 emit pageSet(curPage);
}

/**
 Called to update control after selecting a new page outside of this control
 @param Page selected Page
 @param p unused QSPage reference
 */
void PageTool::updatePage(__attribute__((unused)) const QSPage &p,int page) {
 updatePage(page);
}

/**
 Called to update control after selecting a new page outside of this control
 @param Page selected Page
 */
void PageTool::updatePage(int page) {
 curPage=page;
 updatePage();
}

/** Update the string in this control from internal variables */
void PageTool::updatePage() {
 pageNum->setText(QString::number(curPage));
}

} // namespace gui