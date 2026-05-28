import { useEffect, useMemo, useRef, useState } from 'react';
import { Image, Modal, ScrollView, Text, TouchableWithoutFeedback, View } from 'react-native';
import useScreen from '../domain/screen/useScreen';
import { StoryData, StoryGroup, StoryGroupState, StoryStyling } from './stories/types';
import { personalizeText } from '../domain/actions/utils/personalization';
import StoriesScreen from './stories/screen';

export function Stories() {
  const { campaigns } = useScreen();
  const [viewedSlides, setViewedSlides] = useState<Set<string>>(new Set());
  const [selectedStoryData, setSelectedStoryData] = useState<StoryData | null>(null);

  const campaign = campaigns.find((c) => c.campaign_type === 'STR') as any;

  const orderedGroups = useMemo<StoryGroup[]>(() => {
    if (!campaign) return [];
    const raw = campaign.details;
    // details may be an array of groups or an object with a groups key
    const groups: StoryGroup[] = Array.isArray(raw)
      ? raw
      : Array.isArray(raw?.groups)
      ? raw.groups
      : [];
    const sorted = [...groups].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
    return sorted.map((g) => ({
      ...g,
      slides: g.slides ? [...g.slides].sort((a, b) => (a.order ?? 0) - (b.order ?? 0)) : [],
    }));
  }, [campaign]);

  const isGroupFullyViewed = (group: StoryGroup): boolean => {
    if (!group.slides?.length) return false;
    return group.slides.every((s) => s.id && viewedSlides.has(s.id));
  };

  const sortedGroups = useMemo<StoryGroup[]>(() => {
    return [...orderedGroups].sort((a, b) => {
      const av = isGroupFullyViewed(a);
      const bv = isGroupFullyViewed(b);
      if (av === bv) return 0;
      return av ? 1 : -1;
    });
  }, [orderedGroups, viewedSlides]);

  const markSlideAsViewed = (slideId: string) => {
    setViewedSlides((prev) => new Set([...prev, slideId]));
  };

  const onNavigate = (groupIndex: number) => {
    if (!campaign) return;
    setSelectedStoryData({ groups: sortedGroups, campaignId: campaign.id ?? campaign.campaign_id ?? '', initialGroupIndex: groupIndex });
  };

  if (!sortedGroups.length) return null;

  return (
    <View style={{ width: '100%', flexDirection: 'row', backgroundColor: 'transparent' }}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {sortedGroups
          .filter((g) => g.slides && g.slides.length > 0)
          .map((group, index) => {
            const defaultState: StoryGroupState = { ringColor: '#999999', fontColor: '#000000', fontSize: 14, fontDecoration: [] };
            const defaultStyling: StoryStyling = {
              storyGroupNotViewed: defaultState,
              storyGroupViewed: { ...defaultState, ringColor: '#CCCCCC', fontColor: '#666666' },
            };
            const isViewed = isGroupFullyViewed(group);
            const styling = group.styling ?? defaultStyling;
            const groupState = isViewed
              ? (styling.storyGroupViewed ?? defaultStyling.storyGroupViewed!)
              : (styling.storyGroupNotViewed ?? defaultStyling.storyGroupNotViewed!);

            const size = styling.size && styling.size > 0 ? styling.size : 70;
            const borderWidth = styling.ringWidth && styling.ringWidth > 0 ? styling.ringWidth : 2;
            const deco = groupState.fontDecoration ?? [];

            return (
              <View key={group.id ?? `story-${index}`} style={{ flexDirection: 'row', flex: 1, width: size + 16, backgroundColor: 'transparent', justifyContent: 'center' }}>
                <View style={{ marginTop: 6, flexDirection: 'column', alignItems: 'center' }}>
                  <TouchableWithoutFeedback onPress={() => onNavigate(index)}>
                    <View style={{
                      height: size, width: size,
                      borderTopLeftRadius: styling.cornerRadius?.topLeft ?? size,
                      borderTopRightRadius: styling.cornerRadius?.topRight ?? size,
                      borderBottomLeftRadius: styling.cornerRadius?.bottomLeft ?? size,
                      borderBottomRightRadius: styling.cornerRadius?.bottomRight ?? size,
                      borderWidth, justifyContent: 'center', alignItems: 'center',
                      borderColor: isViewed ? '#CCCCCC' : (group.ringColor ?? '#999'),
                    }}>
                      <Image
                        source={{ uri: group.thumbnail ?? '' }}
                        style={{
                          width: size - 6 - borderWidth * 2,
                          height: size - 6 - borderWidth * 2,
                          borderRadius: size,
                          opacity: isViewed ? 0.6 : 1,
                        }}
                      />
                    </View>
                  </TouchableWithoutFeedback>
                  {group.name ? (
                    <Text style={{
                      marginTop: 6,
                      fontSize: styling.name?.size ?? 14,
                      fontWeight: deco.includes('bold') ? 'bold' : 'normal',
                      fontStyle: deco.includes('italic') ? 'italic' : 'normal',
                      color: isViewed ? '#666666' : (group.nameColor ?? '#000'),
                      textAlign: 'center',
                    }}>
                      {personalizeText(group.name)}
                    </Text>
                  ) : null}
                </View>
              </View>
            );
          })}
      </ScrollView>

      <Modal animationType="none" transparent visible={!!selectedStoryData} onRequestClose={() => setSelectedStoryData(null)}>
        {selectedStoryData && (
          <StoriesScreen
            params={selectedStoryData}
            onClose={() => setSelectedStoryData(null)}
            onSlideViewed={markSlideAsViewed}
          />
        )}
      </Modal>
    </View>
  );
}

export default Stories;
