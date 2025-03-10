<template>
  <div class="user-message">
    <div class="message-wrap" :class="{ 'in-progress': isInProgress }">
      <UserMessageBubble
        v-if="showTextBubble"
        :message="message.content"
        :status="message.status"
      />
      <div v-if="hasAttachment" class="chat-bubble has-attachment user">
        <file-bubble
          v-if="message.attachment && message.attachment.file_type !== 'image'"
          :url="message.attachment.data_url"
          :is-in-progress="isInProgress"
        />
        <image-bubble
          v-else
          :url="message.attachment.data_url"
          :thumb="message.attachment.thumb_url"
          :readable-time="readableTime"
        />
      </div>
    </div>
  </div>
</template>

<script>
import UserMessageBubble from 'widget/components/UserMessageBubble';
import ImageBubble from 'widget/components/ImageBubble';
import FileBubble from 'widget/components/FileBubble';
import timeMixin from 'dashboard/mixins/time';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
    FileBubble,
  },
  mixins: [timeMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    isInProgress() {
      const { status = '' } = this.message;
      return status === 'in_progress';
    },
    hasAttachment() {
      return !!this.message.attachment;
    },
    showTextBubble() {
      const { message } = this;
      return !!message.content;
    },
    readableTime() {
      const { created_at: createdAt = '' } = this.message;
      return this.messageStamp(createdAt);
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.conversation-wrap {
  .user-message {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    margin: 0 $space-smaller $space-micro auto;
    max-width: 85%;
    text-align: right;

    & + .user-message {
      margin-bottom: $space-micro;
      .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
    }
    & + .agent-message {
      margin-top: $space-normal;
      margin-bottom: $space-micro;
    }
    .message-wrap {
      margin-right: $space-small;
    }

    .in-progress {
      opacity: 0.6;
    }
  }

  .has-attachment {
    padding: 0;
    overflow: hidden;
  }
  .user.has-attachment {
    .icon-wrap {
      color: $color-white;
    }

    .download {
      opacity: 0.8;
    }
  }
}
</style>
