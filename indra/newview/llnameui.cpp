/**
 * @file llnameui.cpp
 * @brief Name UI refreshes a name and bears a menu for interacting with it
 *
 * $LicenseInfo:firstyear=2003&license=viewergpl$
 *
 * Copyright (c) 2003-2009, Linden Research, Inc. 2019, Liru F�rs
 *
 * Second Life Viewer Source Code
 * The source code in this file ("Source Code") is provided by Linden Lab
 * to you under the terms of the GNU General Public License, version 2.0
 * ("GPL"), unless you have obtained a separate licensing agreement
 * ("Other License"), formally executed by you and Linden Lab.  Terms of
 * the GPL can be found in doc/GPL-license.txt in this distribution, or
 * online at http://secondlifegrid.net/programs/open_source/licensing/gplv2
 *
 * There are special exceptions to the terms and conditions of the GPL as
 * it is applied to this Source Code. View the full text of the exception
 * in the file doc/FLOSS-exception.txt in this software distribution, or
 * online at
 * http://secondlifegrid.net/programs/open_source/licensing/flossexception
 *
 * By copying, modifying or distributing this software, you acknowledge
 * that you have read and understood your obligations described above,
 * and agree to abide by those obligations.
 *
 * ALL LINDEN LAB SOURCE CODE IS PROVIDED "AS IS." LINDEN LAB MAKES NO
 * WARRANTIES, EXPRESS, IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY,
 * COMPLETENESS OR PERFORMANCE.
 * $/LicenseInfo$
 */

#include "llviewerprecompiledheaders.h"

#include "llnameui.h"

#include "llagentdata.h"
#include "llavataractions.h"
#include "llavatarnamecache.h"
#include "llgroupactions.h"
#include "lltrans.h"

#include "rlvactions.h"
#include "rlvcommon.h"

// statics
std::set<LLNameUI*> LLNameUI::sInstances;

LLNameUI::LLNameUI(const std::string& loading, bool rlv_sensitive, const LLUUID& id, bool is_group)
: mNameID(id), mRLVSensitive(rlv_sensitive), mIsGroup(is_group), mAllowInteract(false)
, mInitialValue(!loading.empty() ? loading : LLTrans::getString("LoadingData"))
{
	if (mIsGroup) sInstances.insert(this);
}

void LLNameUI::setNameID(const LLUUID& name_id, bool is_group)
{
	mNameID = name_id;
	mConnection.disconnect();

	if (mIsGroup != is_group)
	{
		if (is_group)
			sInstances.insert(this);
		else
			sInstances.erase(this);
	}
	mIsGroup = is_group;

	if (mAllowInteract = mNameID.notNull())
	{
		setNameText();
	}
	else
	{
		setText(LLTrans::getString(mIsGroup ? "GroupNameNone" : "AvatarNameNobody"));
		displayAsLink(false);
	}
}

void LLNameUI::setNameText()
{
	std::string name;
	bool got_name = false;

	if (mIsGroup)
	{
		got_name = gCacheName->getGroupName(mNameID, name);
	}
	else
	{
		LLAvatarName av_name;
		if (got_name = LLAvatarNameCache::get(mNameID, &av_name))
			name = mShowCompleteName ? av_name.getCompleteName() : av_name.getNSName();
		else
			mConnection = LLAvatarNameCache::get(mNameID, boost::bind(&LLNameUI::setNameText, this));
	}

	if (!mIsGroup && got_name && mRLVSensitive) // Filter if needed
	{
		if ((RlvActions::hasBehaviour(RLV_BHVR_SHOWNAMES) || RlvActions::hasBehaviour(RLV_BHVR_SHOWNAMETAGS))
			&& mNameID != gAgentID && RlvUtil::isNearbyAgent(mNameID))
		{
			mAllowInteract = false;
			name = RlvStrings::getAnonym(name);
		}
		else mAllowInteract = true;
	}

	displayAsLink(mAllowInteract);

	// Got the name already? Set it.
	// Otherwise it will be set later in refresh().
	setText(got_name ? name : mInitialValue);
}

void LLNameUI::refresh(const LLUUID& id, const std::string& full_name, bool is_group)
{
	if (id == mNameID)
	{
		setNameText();
	}
}

void LLNameUI::refreshAll(const LLUUID& id, const std::string& full_name, bool is_group)
{
	if (!is_group) return;
	for (auto box : sInstances)
	{
		box->refresh(id, full_name, is_group);
	}
}

void LLNameUI::showProfile()
{
	if (!mAllowInteract) return;

	if (mIsGroup)
		LLGroupActions::show(mNameID);
	else
		LLAvatarActions::showProfile(mNameID);
}