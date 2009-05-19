/* ============================================================
 *
 * This file is a part of digiKam project
 * http://www.digikam.org
 *
 * Date        : 2005-02-14
 * Description : a widget to insert a text over an image.
 *
 * Copyright (C) 2005-2009 by Gilles Caulier <caulier dot gilles at gmail dot com>
 * Copyright (C) 2006-2009 by Marcel Wiesweg <marcel dot wiesweg at gmx dot de>
 *
 * This program is free software; you can redistribute it
 * and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation;
 * either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * ============================================================ */

#ifndef INSERTTEXTWIDGET_H
#define INSERTTEXTWIDGET_H

// Qt includes

#include <QColor>
#include <QFont>
#include <QImage>
#include <QMouseEvent>
#include <QPaintEvent>
#include <QPixmap>
#include <QRect>
#include <QResizeEvent>
#include <QSize>
#include <QString>
#include <QWidget>

// KDE includes

#include <kurl.h>

// Local includes

#include "dimg.h"

class QPixmap;

namespace Digikam
{
class ImageIface;
}

namespace DigikamInsertTextImagesPlugin
{

enum Action
{
    ALIGN_LEFT = 0,
    ALIGN_RIGHT,
    ALIGN_CENTER,
    ALIGN_BLOCK,
    BORDER_TEXT,
    TRANSPARENT_TEXT
};

enum TextRotation
{
    ROTATION_NONE = 0,
    ROTATION_90,
    ROTATION_180,
    ROTATION_270
};

enum BorderMode
{
    BORDER_NONE = 0,
    BORDER_SUPPORT,
    BORDER_NORMAL
};

class InsertTextWidgetPriv;

class InsertTextWidget : public QWidget
{
Q_OBJECT

public:

    InsertTextWidget(int w, int h, QWidget *parent=0);
    ~InsertTextWidget();

    Digikam::ImageIface* imageIface();
    Digikam::DImg        makeInsertText(void);

    void   setText(QString text, QFont font, QColor color, int alignMode,
                   bool border, bool transparent, int rotation);
    void   resetEdit(void);

    void  setPositionHint(QRect hint);
    QRect getPositionHint();

protected:

    void paintEvent(QPaintEvent *e);
    void resizeEvent(QResizeEvent * e);
    void mousePressEvent(QMouseEvent * e);
    void mouseReleaseEvent(QMouseEvent * e);
    void mouseMoveEvent(QMouseEvent * e);

    void makePixmap(void);
    QRect composeImage(Digikam::DImg *image, QPainter *destPainter,
                       int x, int y,
                       QFont font, float pointSize, int textRotation, QColor textColor,
                       int alignMode, const QString& textString,
                       bool transparentBackground, QColor backgroundColor,
                       BorderMode borderMode, int borderWidth, int spacing);

private:

    InsertTextWidgetPriv* const d;
};

}  // namespace DigikamInsertTextImagesPlugin

#endif /* INSERTTEXTWIDGET_H */
