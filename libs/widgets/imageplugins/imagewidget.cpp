/* ============================================================
 *
 * This file is a part of digiKam project
 * http://www.digikam.org
 *
 * Date        : 2006-02-01
 * Description : a widget to display an image preview with some 
 *               modes to compare effect results.
 * 
 * Copyright (C) 2006-2007 by Gilles Caulier <caulier dot gilles at gmail dot com>
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

// Qt includes. 

#include <QLayout>
#include <QFrame>
#include <QButtonGroup>
#include <QPushButton>
#include <QGridLayout>
#include <QPixmap>
#include <QVBoxLayout>

// KDE includes.

#include <ksqueezedtextlabel.h>
#include <kdialog.h>
#include <kapplication.h>
#include <klocale.h>
#include <kiconloader.h>
#include <kconfig.h>
#include <kstandarddirs.h>
#include <kglobal.h>

// Local includes

#include "ddebug.h"
#include "imagewidget.h"
#include "imagewidget.moc"

namespace Digikam
{

class ImageWidgetPriv
{
public:

    ImageWidgetPriv()
    {
        spotInfoLabel       = 0;
        previewButtons      = 0;
        underExposureButton = 0;
        overExposureButton  = 0;
        previewWidget       = 0;
        prevBBox            = 0;
        expoBBox            = 0;
    }

    QWidget            *prevBBox;
    QWidget            *expoBBox;

    QString             settingsSection;

    QButtonGroup       *previewButtons;

    QPushButton        *underExposureButton;
    QPushButton        *overExposureButton;

    KSqueezedTextLabel *spotInfoLabel;

    ImageGuideWidget   *previewWidget;
};

ImageWidget::ImageWidget(const QString& settingsSection, QWidget *parent, 
                         const QString& previewWhatsThis, bool prevModeOptions, 
                         int guideMode, bool guideVisible, bool useImageSelection)
           : QWidget(parent)
{
    d = new ImageWidgetPriv;
    d->settingsSection = settingsSection;

    // -------------------------------------------------------------
    
    QGridLayout* grid = new QGridLayout(this);
    d->spotInfoLabel  = new KSqueezedTextLabel(this);
    d->spotInfoLabel->setAlignment(Qt::AlignRight);

    // -------------------------------------------------------------
    
    d->prevBBox       = new QWidget(this);
    QHBoxLayout *hlay = new QHBoxLayout(d->prevBBox);
    d->previewButtons = new QButtonGroup(d->prevBBox);
    d->previewButtons->setExclusive(true);
    hlay->setSpacing(0);
    hlay->setMargin(0);

    QPushButton *previewOriginalButton = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewOriginalButton, ImageGuideWidget::PreviewOriginalImage);
    hlay->addWidget(previewOriginalButton);
    previewOriginalButton->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/original.png")));
    previewOriginalButton->setCheckable(true);
    previewOriginalButton->setWhatsThis( i18n( "<p>If you enable this option, you will see "
                                               "the original image." ) );

    QPushButton *previewBothButtonVert = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewBothButtonVert, ImageGuideWidget::PreviewBothImagesVertCont);
    hlay->addWidget(previewBothButtonVert);
    previewBothButtonVert->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/bothvert.png")));
    previewBothButtonVert->setCheckable(true);
    previewBothButtonVert->setWhatsThis( i18n( "<p>If you enable this option, the preview area will "
                                               "be separated vertically. "
                                               "A contiguous area of the image will be shown, "
                                               "with one half from the original image, "
                                               "the other half from the target image.") );

    QPushButton *previewBothButtonHorz = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewBothButtonHorz, ImageGuideWidget::PreviewBothImagesHorzCont);
    hlay->addWidget(previewBothButtonHorz);
    previewBothButtonHorz->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/bothhorz.png")));
    previewBothButtonHorz->setCheckable(true);
    previewBothButtonHorz->setWhatsThis( i18n( "<p>If you enable this option, the preview area will "
                                               "be separated horizontally. "
                                               "A contiguous area of the image will be shown, "
                                               "with one half from the original image, "
                                               "the other half from the target image.") );

    QPushButton *previewDuplicateBothButtonVert = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewDuplicateBothButtonVert, ImageGuideWidget::PreviewBothImagesVert);
    hlay->addWidget(previewDuplicateBothButtonVert);
    previewDuplicateBothButtonVert->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/duplicatebothvert.png")));
    previewDuplicateBothButtonVert->setCheckable(true);
    previewDuplicateBothButtonVert->setWhatsThis( i18n( "<p>If you enable this option, the preview area will "
                                                        "be separated vertically. "
                                                        "The same part of the original and the target image "
                                                        "will be shown side by side.") );

    QPushButton *previewDupplicateBothButtonHorz = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewDupplicateBothButtonHorz, ImageGuideWidget::PreviewBothImagesHorz);
    hlay->addWidget(previewDupplicateBothButtonHorz);
    previewDupplicateBothButtonHorz->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/duplicatebothhorz.png")));
    previewDupplicateBothButtonHorz->setCheckable(true);
    previewDupplicateBothButtonHorz->setWhatsThis( i18n( "<p>If you enable this option, the preview area will "
                                                         "be separated horizontally. "
                                                         "The same part of the original and the target image "
                                                         "will be shown side by side.") );

    QPushButton *previewtargetButton = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewtargetButton, ImageGuideWidget::PreviewTargetImage);
    hlay->addWidget(previewtargetButton);
    previewtargetButton->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/target.png")));
    previewtargetButton->setCheckable(true);
    previewtargetButton->setWhatsThis( i18n( "<p>If you enable this option, you will see "
                                             "the target image." ) );

    QPushButton *previewToggleMouseOverButton = new QPushButton( d->prevBBox );
    d->previewButtons->addButton(previewToggleMouseOverButton, ImageGuideWidget::PreviewToggleOnMouseOver);
    hlay->addWidget(previewToggleMouseOverButton);
    previewToggleMouseOverButton->setIcon(QPixmap(KStandardDirs::locate("data", "digikam/data/togglemouseover.png")));
    previewToggleMouseOverButton->setCheckable(true);
    previewToggleMouseOverButton->setWhatsThis( i18n( "<p>If you enable this option, you will see "
                                                      "the original image when the mouse is over image area, "
                                                      "else the target image." ) );

    // -------------------------------------------------------------
    
    d->expoBBox                   = new QWidget(this);
    QHBoxLayout *hlay2            = new QHBoxLayout(d->expoBBox);
    QButtonGroup *exposureButtons = new QButtonGroup(d->expoBBox);
    hlay2->setSpacing(0);
    hlay2->setMargin(0);

    d->underExposureButton = new QPushButton(d->expoBBox);
    exposureButtons->addButton(d->underExposureButton, UnderExposure);
    hlay2->addWidget(d->underExposureButton);
    d->underExposureButton->setIcon(SmallIcon("underexposure"));
    d->underExposureButton->setCheckable(true);
    d->underExposureButton->setWhatsThis( i18n("<p>Set this option on to display pure black "
                                               "over-colored on preview. This will help you to avoid "
                                               "under-exposing the image." ) );

    d->overExposureButton = new QPushButton(d->expoBBox);
    exposureButtons->addButton(d->overExposureButton, OverExposure);
    hlay2->addWidget(d->overExposureButton);
    d->overExposureButton->setIcon(SmallIcon("overexposure"));
    d->overExposureButton->setCheckable(true);
    d->overExposureButton->setWhatsThis( i18n("<p>Set this option on to display pure white "
                                              "over-colored on preview. This will help you to avoid "
                                              "over-exposing the image." ) );

    // -------------------------------------------------------------
    
    QFrame *frame    = new QFrame(this);
    frame->setFrameStyle(QFrame::Panel|QFrame::Sunken);
    QVBoxLayout* l   = new QVBoxLayout(frame);
    l->setMargin(5);
    l->setSpacing(0);
    d->previewWidget = new ImageGuideWidget(480, 320, frame, guideVisible, 
                                            guideMode, Qt::red, 1, false, 
                                            useImageSelection);
    d->previewWidget->setWhatsThis(previewWhatsThis);
    l->addWidget(d->previewWidget, 0);

    // -------------------------------------------------------------
    
    grid->addMultiCellWidget(d->prevBBox, 1, 1, 0, 0);
    grid->addMultiCellWidget(d->spotInfoLabel, 1, 1, 1, 1);
    grid->addMultiCellWidget(d->expoBBox, 1, 1, 3, 3);
    grid->addMultiCellWidget(frame, 3, 3, 0, 3);
    grid->setColumnMinimumWidth(2, KDialog::spacingHint());
    grid->setColumnMinimumWidth(1, KDialog::spacingHint());
    grid->setRowMinimumHeight(0, KDialog::spacingHint());
    grid->setRowMinimumHeight(2, KDialog::spacingHint());
    grid->setRowStretch(3, 10);
    grid->setColumnStretch(1, 10);
    grid->setSpacing(0);
    grid->setMargin(0);

    // -------------------------------------------------------------
    
    connect(d->previewWidget, SIGNAL(signalResized()),
            this, SIGNAL(signalResized()));

    connect(d->previewWidget, SIGNAL(spotPositionChangedFromOriginal(const Digikam::DColor&, const QPoint&)),
            this, SIGNAL(spotPositionChangedFromOriginal(const Digikam::DColor &, const QPoint &)));

    connect(d->previewWidget, SIGNAL(spotPositionChangedFromOriginal(const Digikam::DColor&, const QPoint&)),
            this, SLOT(slotUpdateSpotInfo(const Digikam::DColor&, const QPoint&)));
    
    connect(d->previewWidget, SIGNAL(spotPositionChangedFromTarget(const Digikam::DColor&, const QPoint&)),
            this, SIGNAL(spotPositionChangedFromTarget(const Digikam::DColor&, const QPoint&)));

    connect(d->previewWidget, SIGNAL(spotPositionChangedFromTarget(const Digikam::DColor&, const QPoint&)),
            this, SLOT(slotUpdateSpotInfo(const Digikam::DColor&, const QPoint&)));

    connect(d->previewButtons, SIGNAL(buttonReleased(int)),
            d->previewWidget, SLOT(slotChangeRenderingPreviewMode(int)));

    connect(d->underExposureButton, SIGNAL(toggled(bool)),
            d->previewWidget, SLOT(slotToggleUnderExposure(bool)));

    connect(d->overExposureButton, SIGNAL(toggled(bool)),
            d->previewWidget, SLOT(slotToggleOverExposure(bool)));

    // -------------------------------------------------------------
    
    if (prevModeOptions)
        readSettings();
    else
    {
        setRenderingPreviewMode(ImageGuideWidget::NoPreviewMode);
        d->spotInfoLabel->hide();
        d->prevBBox->hide();    
        d->expoBBox->hide();
    }     
}

ImageWidget::~ImageWidget()
{
    writeSettings();
    delete d;
}

ImageIface* ImageWidget::imageIface()
{
    return d->previewWidget->imageIface();
}

void ImageWidget::updatePreview()
{
    d->previewWidget->updatePreview();
}

void ImageWidget::slotChangeGuideColor(const QColor &color)
{
    d->previewWidget->slotChangeGuideColor(color);
}

void ImageWidget::slotChangeGuideSize(int size)
{
    d->previewWidget->slotChangeGuideSize(size);
}

void ImageWidget::resetSpotPosition()
{
    d->previewWidget->resetSpotPosition();
}

QPoint ImageWidget::getSpotPosition(void)
{
    return ( d->previewWidget->getSpotPosition() );
}

DColor ImageWidget::getSpotColor(int getColorFrom)
{
    return ( d->previewWidget->getSpotColor(getColorFrom) );
}

void ImageWidget::setSpotVisible(bool spotVisible, bool blink)
{
    d->previewWidget->setSpotVisible(spotVisible, blink);
}

int ImageWidget::getRenderingPreviewMode()
{
    return ( d->previewWidget->getRenderingPreviewMode() );
}
    
void ImageWidget::setRenderingPreviewMode(int mode)
{
    if (d->previewButtons->button(mode))
        d->previewButtons->button(mode)->setChecked(true);
    
    d->previewWidget->slotChangeRenderingPreviewMode(mode);
}

void ImageWidget::slotUpdateSpotInfo(const Digikam::DColor &col, const QPoint &point)
{
    DColor color = col;
    d->spotInfoLabel->setText(i18n("(%1,%2) RGBA:%3,%4,%5,%6", 
                              point.x(), point.y(),
                              color.red(), color.green(), 
                              color.blue(), color.alpha()));
}

void ImageWidget::readSettings(void)
{
    KSharedConfig::Ptr config = KGlobal::config();
    KConfigGroup group = config->group(d->settingsSection);

    d->underExposureButton->setChecked(group.readEntry("Under Exposure Indicator", false));
    d->overExposureButton->setChecked(group.readEntry("Over Exposure Indicator", false));

    int mode = group.readEntry("Separate View", (int)ImageGuideWidget::PreviewBothImagesVertCont);
    mode = qMax((int)ImageGuideWidget::PreviewOriginalImage, mode);
    mode = qMin((int)ImageGuideWidget::NoPreviewMode, mode);
    setRenderingPreviewMode(mode);
}
    
void ImageWidget::writeSettings(void)
{
    KSharedConfig::Ptr config = KGlobal::config();
    KConfigGroup group = config->group(d->settingsSection);
    group.writeEntry("Separate View", getRenderingPreviewMode());
    group.writeEntry("Under Exposure Indicator", d->underExposureButton->isChecked());
    group.writeEntry("Over Exposure Indicator", d->overExposureButton->isChecked());
    config->sync();
}

}  // namespace Digikam

