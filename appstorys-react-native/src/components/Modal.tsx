import { useEffect, useState } from 'react';
import trackEvent from '../domain/actions/trackEvent';
import { removeTrackedEvent } from '../domain/actions/utils/viaAppStorys';
import FullPageCarouselModal from './modals/FullPageCarouselModal';
import MediaOnlyModal from './modals/MediaOnlyModal';
import ModalWithCTA from './modals/ModalWithCTA';
import AppStorys from '../index';
import useScreen from '../domain/screen/useScreen';

export default function Modal() {
  const [isModalVisible, setIsModalVisible] = useState(false);

  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'MOD') as any;
  const modalDetails = data?.details || null;
  const modal = modalDetails?.modals?.[0];

  useEffect(() => {
    if (data?.id && modalDetails && modal) {
      setIsModalVisible(true);
      void trackEvent('viewed', data.id);
    }
  }, [data?.id, modalDetails, modal]);

  const handleCloseClick = () => {
    setIsModalVisible(false);
    if (data?.id) removeTrackedEvent(`viaAppStorys${data.id}`);
  };

  const handleModalClick = (link?: string) => {
    if (data?.id && link) {
      void trackEvent('clicked', data.id);
      AppStorys.handleNavigation(link);
    }
  };

  const handlePrimaryCta = (link?: string) => {
    if (link) {
      void trackEvent('clicked', data?.id || '', { cta_type: 'primary' });
      AppStorys.handleNavigation(link);
    }
  };

  const handleSecondaryCta = (link?: string) => {
    if (link) {
      void trackEvent('clicked', data?.id || '', { cta_type: 'secondary' });
      AppStorys.handleNavigation(link);
    }
  };

  if (!modalDetails || !isModalVisible || !modal) return null;

  const content = (modal as any).content;
  const modalType = (modal as any).modalType;
  const isCarousel = content?.set && Array.isArray(content.set) && content.set.length > 0;
  const isMediaOnly =
    modalType?.toLowerCase().includes('media-only') ||
    (!content?.titleText && !content?.subtitleText && !content?.primaryCtaText && !content?.secondaryCtaText);

  if (isCarousel || modalType?.toLowerCase().includes('carousel')) {
    return (
      <FullPageCarouselModal
        modalDetails={modalDetails}
        onClose={handleCloseClick}
        onModalClick={handleModalClick}
        onPrimaryCta={handlePrimaryCta}
        onSecondaryCta={handleSecondaryCta}
      />
    );
  }

  if (isMediaOnly) {
    return <MediaOnlyModal modal={modal} onClose={handleCloseClick} onModalClick={handleModalClick} />;
  }

  return <ModalWithCTA modal={modal} onClose={handleCloseClick} onPrimaryCta={handlePrimaryCta} onSecondaryCta={handleSecondaryCta} />;
}

export { Modal };
