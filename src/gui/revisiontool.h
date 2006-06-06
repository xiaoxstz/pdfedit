#ifndef __REVISIONTOOL_H__
#define __REVISIONTOOL_H__

#include <qwidget.h>

class QComboBox;

namespace pdfobjects {
 class CPdf;
}

namespace gui {

/** 
 Toolbutton listing revisions of current PDF document, with ability to switch revisions<br>
 Can be placed in toolbar in place of ordinary button
*/
class RevisionTool : public QWidget {
Q_OBJECT
public:
 RevisionTool(QWidget *parent=0,const char *name=NULL);
 ~RevisionTool();
 QSize sizeHint() const;
public slots:
 void updateRevision(int revision);
 void selectRevision(int revision);
 void setDocument(pdfobjects::CPdf *newDocument);
signals:
 /**
  Signal emitted when user changes the revision in this control
  @param revision number of selected revision
 */
 void revisionChanged(int revision);
protected:
 void resizeEvent (QResizeEvent *e);
protected:
 /** Revision selection list */
 QComboBox *revList;
 /** Reference to current PDF document */
 pdfobjects::CPdf *document;
};

} // namespace gui

#endif
