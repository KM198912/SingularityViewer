/**
 * @file llcontrolavatar.h
 * @brief Special dummy avatar used to drive rigged meshes.
 *
 * $LicenseInfo:firstyear=2017&license=viewerlgpl$
 * Second Life Viewer Source Code
 * Copyright (C) 2017, Linden Research, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 2.1 of the License only.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Linden Research, Inc., 945 Battery Street, San Francisco, CA  94111  USA
 * $/LicenseInfo$
 */

#ifndef LL_CONTROLAVATAR_H
#define LL_CONTROLAVATAR_H

#include "llvoavatar.h"
#include "llvovolume.h"

class LLControlAvatar:
    public LLVOAvatar
{
    LOG_CLASS(LLControlAvatar);

public:
    LLControlAvatar(const LLUUID &id, const LLPCode pcode, LLViewerRegion *regionp);
	virtual void 			initInstance(); // Called after construction to initialize the class.
	virtual	~LLControlAvatar();
	virtual LLControlAvatar* asControlAvatar() { return this; }

    void getNewConstraintFixups(LLVector3& new_pos_constraint, F32& new_scale_constraint) const;
    void matchVolumeTransform();
    void updateVolumeGeom();

    void setGlobalScale(F32 scale);
    void recursiveScaleJoint(LLJoint *joint, F32 factor);
    static LLControlAvatar *createControlAvatar(LLVOVolume *obj);

    // Delayed kill so we don't make graphics pipeline unhappy calling
    // markDead() inside other graphics pipeline operations.
    void markForDeath();

    virtual void idleUpdate(LLAgent &agent, LLWorld &world, const F64 &time);
	virtual BOOL updateCharacter(LLAgent &agent);

    void getAnimatedVolumes(std::vector<LLVOVolume*>& volumes);
    void updateAnimations();  
    
	virtual LLViewerObject*	lineSegmentIntersectRiggedAttachments(
        const LLVector4a& start, const LLVector4a& end,
        S32 face = -1,                    // which face to check, -1 = ALL_SIDES
        BOOL pick_transparent = FALSE,
        BOOL pick_rigged = FALSE,
        S32* face_hit = NULL,             // which face was hit
        LLVector4a* intersection = NULL,   // return the intersection point
        LLVector2* tex_coord = NULL,      // return the texture coordinates of the intersection point
        LLVector4a* normal = NULL,         // return the surface normal at the intersection point
        LLVector4a* tangent = NULL);     // return the surface tangent at the intersection point

	virtual void	updateDebugText();

    virtual std::string getFullname() const;

    virtual bool shouldRenderRigged() const;

	virtual BOOL isImpostor(); 
    
    bool mPlaying;

    F32 mGlobalScale;

    LLVOVolume *mRootVolp;

    bool mMarkedForDeath;

    LLVector3 mPositionConstraintFixup;
    F32 mScaleConstraintFixup;

    static const F32 MAX_LEGAL_OFFSET;
    static const F32 MAX_LEGAL_SIZE;

	static void onRegionChanged();
	bool mRegionChanged;
	static boost::signals2::connection sRegionChangedSlot;
};

typedef std::map<LLUUID, S32> signaled_animation_map_t;
typedef std::map<LLUUID, signaled_animation_map_t> object_signaled_animation_map_t;

// Stores information about previously requested animations, by object id.
class LLObjectSignaledAnimationMap: public LLSingleton<LLObjectSignaledAnimationMap>
{
public:
	LLObjectSignaledAnimationMap() {}

    object_signaled_animation_map_t mMap;

    object_signaled_animation_map_t& getMap() { return mMap; }
};

#endif //LL_CONTROLAVATAR_H
