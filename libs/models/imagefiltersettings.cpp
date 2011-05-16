/* ============================================================
 *
 * This file is a part of digiKam project
 * http://www.digikam.org
 *
 * Date        : 2009-03-05
 * Description : Filter values for use with ImageFilterModel
 *
 * Copyright (C) 2009-2011 by Marcel Wiesweg <marcel dot wiesweg at gmx dot de>
 * Copyright (C)      2011 by Gilles Caulier <caulier dot gilles at gmail dot com>
 * Copyright (C)      2010 by Andi Clemens <andi dot clemens at gmx dot net>
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

#include "imagefiltersettings.h"

// Qt includes

#include <QDateTime>

// KDE includes

#include <kdebug.h>

// Local includes

#include "databasefields.h"
#include "imageinfo.h"
#include "tagscache.h"
#include "versionmanagersettings.h"

namespace Digikam
{

ImageFilterSettings::ImageFilterSettings()
{
    m_untaggedFilter = false;
    m_ratingFilter   = 0;
    m_mimeTypeFilter = MimeFilter::AllFiles;
    m_ratingCond     = GreaterEqualCondition;
    m_matchingCond   = OrCondition;
}

DatabaseFields::Set ImageFilterSettings::watchFlags() const
{
    DatabaseFields::Set set;

    if (isFilteringByDay())
    {
        set |= DatabaseFields::CreationDate;
    }

    if (isFilteringByText())
    {
        set |= DatabaseFields::Name;
        set |= DatabaseFields::Comment;
    }

    if (isFilteringByRating())
    {
        set |= DatabaseFields::Rating;
    }

    if (isFilteringByTypeMime())
    {
        set |= DatabaseFields::Category;
        set |= DatabaseFields::Format;
    }

    if (isFilteringByColorLabels())
    {
        set |= DatabaseFields::ColorLabel;
    }

    if (isFilteringByPickLabels())
    {
        set |= DatabaseFields::PickLabel;
    }

    return set;
}

bool ImageFilterSettings::isFilteringByDay() const
{
    if (!m_dayFilter.isEmpty())
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByTags() const
{
    if (!m_includeTagFilter.isEmpty() || !m_excludeTagFilter.isEmpty() || m_untaggedFilter)
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByColorLabels() const
{
    if (!m_colorLabelTagFilter.isEmpty())
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByPickLabels() const
{
    if (!m_pickLabelTagFilter.isEmpty())
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByText() const
{
    if (!m_textFilterSettings.text.isEmpty())
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByTypeMime() const
{
    if (m_mimeTypeFilter != MimeFilter::AllFiles)
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringByRating() const
{
    if (m_ratingFilter != 0 || m_ratingCond != GreaterEqualCondition)
    {
        return true;
    }

    return false;
}

bool ImageFilterSettings::isFilteringInternally() const
{
    return isFiltering() || !m_urlWhitelists.isEmpty() || !m_idWhitelists.isEmpty();
}

bool ImageFilterSettings::isFiltering() const
{
    return isFilteringByDay()         ||
           isFilteringByTags()        ||
           isFilteringByText()        ||
           isFilteringByRating()      ||
           isFilteringByTypeMime()    || 
           isFilteringByColorLabels() || 
           isFilteringByPickLabels();
}

void ImageFilterSettings::setDayFilter(const QList<QDateTime>& days)
{
    m_dayFilter.clear();

    for (QList<QDateTime>::const_iterator it = days.constBegin(); it != days.constEnd(); ++it)
    {
        m_dayFilter.insert(*it, true);
    }
}

void ImageFilterSettings::setTagFilter(const QList<int>& includedTags, const QList<int>& excludedTags,
                                       MatchingCondition matchingCondition, bool showUnTagged,
                                       const QList<int>& clTagIds, const QList<int>& plTagIds)
{
    m_includeTagFilter    = includedTags;
    m_excludeTagFilter    = excludedTags;
    m_matchingCond        = matchingCondition;
    m_untaggedFilter      = showUnTagged;
    m_colorLabelTagFilter = clTagIds;
    m_pickLabelTagFilter  = plTagIds;
}

void ImageFilterSettings::setRatingFilter(int rating, RatingCondition ratingCondition)
{
    m_ratingFilter = rating;
    m_ratingCond   = ratingCondition;
}

void ImageFilterSettings::setMimeTypeFilter(int mime)
{
    m_mimeTypeFilter = (MimeFilter::TypeMimeFilter)mime;
}

void ImageFilterSettings::setTextFilter(const SearchTextFilterSettings& settings)
{
    m_textFilterSettings = settings;
}

void ImageFilterSettings::setTagNames(const QHash<int, QString>& hash)
{
    m_tagNameHash = hash;
}

void ImageFilterSettings::setAlbumNames(const QHash<int, QString>& hash)
{
    m_albumNameHash = hash;
}

void ImageFilterSettings::setUrlWhitelist(const KUrl::List& urlList, const QString& id)
{
    if (urlList.isEmpty())
    {
        m_urlWhitelists.remove(id);
    }
    else
    {
        m_urlWhitelists.insert(id, urlList);
    }
}

void ImageFilterSettings::setIdWhitelist(const QList<qlonglong>& idList, const QString& id)
{
    if (idList.isEmpty())
    {
        m_idWhitelists.remove(id);
    }
    else
    {
        m_idWhitelists.insert(id, idList);
    }
}

bool ImageFilterSettings::matches(const ImageInfo& info, bool* foundText) const
{
    if (foundText)
    {
        *foundText = false;
    }

    if (!isFilteringInternally())
    {
        return true;
    }

    bool match = false;

    if (!m_includeTagFilter.isEmpty() || !m_excludeTagFilter.isEmpty())
    {
        QList<int> tagIds = info.tagIds();
        QList<int>::const_iterator it;

        match = m_includeTagFilter.isEmpty();

        if (m_matchingCond == OrCondition)
        {
            for (it = m_includeTagFilter.begin(); it != m_includeTagFilter.end(); ++it)
            {
                if (tagIds.contains(*it))
                {
                    match = true;
                    break;
                }
            }

            match |= (m_untaggedFilter && tagIds.isEmpty());
        }
        else // AND matching condition...
        {
            // m_untaggedFilter and non-empty tag filter, combined with AND, is logically no match
            if (!m_untaggedFilter)
            {
                for (it = m_includeTagFilter.begin(); it != m_includeTagFilter.end(); ++it)
                {
                    if (!tagIds.contains(*it))
                    {
                        break;
                    }
                }

                if (it == m_includeTagFilter.end())
                {
                    match = true;
                }
            }
        }

        for (it = m_excludeTagFilter.begin(); it != m_excludeTagFilter.end(); ++it)
        {
            if (tagIds.contains(*it))
            {
                match = false;
                break;
            }
        }
    }
    else if (m_untaggedFilter)
    {
        match = info.tagIds().isEmpty();
    }
    else
    {
        match = true;
    }

    //-- Filter by pick labels ------------------------------------------------

    if (!m_pickLabelTagFilter.isEmpty())
    {
        bool matchPL      = false;
        QList<int> tagIds = info.tagIds();

        for (QList<int>::const_iterator it = m_pickLabelTagFilter.begin(); it != m_pickLabelTagFilter.end(); ++it)
        {
            if (tagIds.contains(*it))
            {
                matchPL = true;
                break;
            }
        }

        match &= matchPL;
    }

    //-- Filter by color labels ------------------------------------------------

    if (!m_colorLabelTagFilter.isEmpty())
    {
        bool matchCL      = false;
        QList<int> tagIds = info.tagIds();

        for (QList<int>::const_iterator it = m_colorLabelTagFilter.begin(); it != m_colorLabelTagFilter.end(); ++it)
        {
            if (tagIds.contains(*it))
            {
                matchCL = true;
                break;
            }
        }

        match &= matchCL;
    }

    //-- Filter by date -----------------------------------------------------------

    if (!m_dayFilter.isEmpty())
    {
        match &= m_dayFilter.contains(QDateTime(info.dateTime().date(), QTime()));
    }

    //-- Filter by rating ---------------------------------------------------------

    if (m_ratingFilter >= 0)
    {
        // for now we treat -1 (no rating) just like a rating of 0.
        int rating = info.rating();

        if (rating == -1)
        {
            rating = 0;
        }

        if (m_ratingCond == GreaterEqualCondition)
        {
            // If the rating is not >=, i.e it is <, then it does not match.
            if (rating < m_ratingFilter)
            {
                match = false;
            }
        }
        else if (m_ratingCond == EqualCondition)
        {
            // If the rating is not =, i.e it is !=, then it does not match.
            if (rating != m_ratingFilter)
            {
                match = false;
            }
        }
        else
        {
            // If the rating is not <=, i.e it is >, then it does not match.
            if (rating > m_ratingFilter)
            {
                match = false;
            }
        }
    }

    // -- Filter by mime type -----------------------------------------------------

    switch (m_mimeTypeFilter)
    {
            // info.format is a standardized string: Only one possibility per mime type
        case MimeFilter::ImageFiles:
        {
            if (info.category() != DatabaseItem::Image)
            {
                match = false;
            }

            break;
        }
        case MimeFilter::JPGFiles:
        {
            if (info.format() != "JPG")
            {
                match = false;
            }

            break;
        }
        case MimeFilter::PNGFiles:
        {
            if (info.format() != "PNG")
            {
                match = false;
            }

            break;
        }
        case MimeFilter::TIFFiles:
        {
            if (info.format() != "TIFF")
            {
                match = false;
            }

            break;
        }
        case MimeFilter::DNGFiles:
        {
            if (info.format() != "RAW-DNG")
            {
                match = false;
            }

            break;
        }
        case MimeFilter::NoRAWFiles:
        {
            if (info.format().startsWith(QLatin1String("RAW")))
            {
                match = false;
            }

            break;
        }
        case MimeFilter::RAWFiles:
        {
            if (!info.format().startsWith(QLatin1String("RAW")))
            {
                match = false;
            }

            break;
        }
        case MimeFilter::MoviesFiles:
        {
            if (info.category() != DatabaseItem::Video)
            {
                match = false;
            }

            break;
        }
        case MimeFilter::AudioFiles:
        {
            if (info.category() != DatabaseItem::Audio)
            {
                match = false;
            }

            break;
        }
        case MimeFilter::RasterFiles:
        {
            if (info.format() != "PSD" &&         // Adobe Photoshop Document
                info.format() != "PSB" &&         // Adobe Photoshop Big
                info.format() != "XCF" &&         // Gimp
                info.format() != "KRA" &&         // Krita
                info.format() != "ORA"            // Open Raster
               )
            {
                match = false;
            }

            break;
        }
        default:
        {
            // All Files: do nothing...
            break;
        }
    }

    //-- Filter by text -----------------------------------------------------------

    if (!m_textFilterSettings.text.isEmpty())
    {
        bool textMatch = false;

        // Image name
        if (m_textFilterSettings.textFields & SearchTextFilterSettings::ImageName &&
            info.name().contains(m_textFilterSettings.text, m_textFilterSettings.caseSensitive))
        {
            textMatch = true;
        }

        // Image comment
        if (m_textFilterSettings.textFields & SearchTextFilterSettings::ImageComment &&
            info.comment().contains(m_textFilterSettings.text, m_textFilterSettings.caseSensitive))
        {
            textMatch = true;
        }

        // Tag names
        foreach (int id, info.tagIds())
        {
            if (m_textFilterSettings.textFields & SearchTextFilterSettings::TagName &&
                m_tagNameHash.value(id).contains(m_textFilterSettings.text, m_textFilterSettings.caseSensitive))
            {
                textMatch = true;
            }
        }

        // Album names
        if (m_textFilterSettings.textFields & SearchTextFilterSettings::AlbumName &&
            m_albumNameHash.value(info.albumId()).contains(m_textFilterSettings.text,
                                                           m_textFilterSettings.caseSensitive))
        {
            textMatch = true;
        }

        match &= textMatch;

        if (foundText)
        {
            *foundText = textMatch;
        }
    }

    // -- filter by URL-whitelists ------------------------------------------------
    // NOTE: whitelists are always AND for now.

    if (match)
    {
        const KUrl url = info.fileUrl();

        for (QHash<QString, KUrl::List>::const_iterator it = m_urlWhitelists.constBegin(); it!=m_urlWhitelists.constEnd(); ++it)
        {
            match = it->contains(url);

            if (!match)
            {
                break;
            }
        }
    }

    if (match)
    {
        const qlonglong id = info.id();

        for (QHash<QString, QList<qlonglong> >::const_iterator it = m_idWhitelists.constBegin(); it!=m_idWhitelists.constEnd(); ++it)
        {
            match = it->contains(id);

            if (!match)
            {
                break;
            }
        }
    }

    return match;
}

// -------------------------------------------------------------------------------------------------

VersionImageFilterSettings::VersionImageFilterSettings()
{
}

VersionImageFilterSettings::VersionImageFilterSettings(const VersionManagerSettings& settings)
{
    setVersionManagerSettings(settings);
}

bool VersionImageFilterSettings::operator==(const VersionImageFilterSettings& other) const
{
    return m_excludeTagFilter == other.m_excludeTagFilter &&
           m_exceptionLists   == other.m_exceptionLists;
}

bool VersionImageFilterSettings::matches(const ImageInfo& info) const
{
    if (!isFiltering())
    {
        return true;
    }

    const qlonglong id = info.id();

    for (QHash<QString, QList<qlonglong> >::const_iterator it = m_exceptionLists.constBegin();
         it != m_exceptionLists.constEnd(); ++it)
    {
        if (it->contains(id))
        {
            return true;
        }
    }

    bool match        = true;
    QList<int> tagIds = info.tagIds();

    if (!tagIds.contains(m_includeTagFilter))
    {
        for (QList<int>::const_iterator it = m_excludeTagFilter.begin();
            it != m_excludeTagFilter.end(); ++it)
        {
            if (tagIds.contains(*it))
            {
                match = false;
                break;
            }
        }
    }

    if (!match)
    {
        if (tagIds.contains(m_exceptionTagFilter))
        {
            match = true;
        }
    }

    return match;
}

bool VersionImageFilterSettings::isHiddenBySettings(const ImageInfo& info) const
{
    QList<int> tagIds = info.tagIds();
    foreach (int tagId, m_excludeTagFilter)
    {
        if (tagIds.contains(tagId))
        {
            return true;
        }
    }
    return false;
}

bool VersionImageFilterSettings::isExemptedBySettings(const ImageInfo& info) const
{
    return info.tagIds().contains(m_exceptionTagFilter);
}

void VersionImageFilterSettings::setVersionManagerSettings(const VersionManagerSettings& settings)
{
    m_excludeTagFilter.clear();

    if (!(settings.showInViewFlags & VersionManagerSettings::ShowOriginal))
    {
        m_excludeTagFilter << TagsCache::instance()->getOrCreateInternalTag(InternalTagName::originalVersion());
    }

    if (!(settings.showInViewFlags & VersionManagerSettings::ShowIntermediates))
    {
        m_excludeTagFilter << TagsCache::instance()->getOrCreateInternalTag(InternalTagName::intermediateVersion());
    }

    m_includeTagFilter   = TagsCache::instance()->getOrCreateInternalTag(InternalTagName::currentVersion());
    m_exceptionTagFilter = TagsCache::instance()->getOrCreateInternalTag(InternalTagName::versionAlwaysVisible());
}

void VersionImageFilterSettings::setExceptionList(const QList<qlonglong>& idList, const QString& id)
{
    if (idList.isEmpty())
    {
        m_exceptionLists.remove(id);
    }
    else
    {
        m_exceptionLists.insert(id, idList);
    }
}

bool VersionImageFilterSettings::isFiltering() const
{
    return !m_excludeTagFilter.isEmpty();
}

bool VersionImageFilterSettings::isFilteringByTags() const
{
    return isFiltering();
}

// -------------------------------------------------------------------------------------------------

GroupImageFilterSettings::GroupImageFilterSettings()
    : m_allOpen(false)
{
}

bool GroupImageFilterSettings::operator==(const GroupImageFilterSettings& other) const
{
    return m_allOpen == other.m_allOpen &&
           m_openGroups == other.m_openGroups;
}

bool GroupImageFilterSettings::matches(const ImageInfo& info) const
{
    if (m_allOpen)
    {
        return true;
    }

    if (info.isGrouped())
    {
        return m_openGroups.contains(info.groupImage().id());
    }
    return true;
}

void GroupImageFilterSettings::setOpen(qlonglong group, bool open)
{
    if (open)
    {
        m_openGroups << group;
    }
    else
    {
        m_openGroups.remove(group);
    }
}

bool GroupImageFilterSettings::isOpen(qlonglong group) const
{
    return m_openGroups.contains(group);
}

void GroupImageFilterSettings::setAllOpen(bool open)
{
    m_allOpen = open;
}

bool GroupImageFilterSettings::isAllOpen() const
{
    return m_allOpen;
}

bool GroupImageFilterSettings::isFiltering() const
{
    return !m_allOpen;
}

DatabaseFields::Set GroupImageFilterSettings::watchFlags() const
{
    return DatabaseFields::ImageRelations;
}

} // namespace Digikam
