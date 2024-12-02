param serviceBusNamespaceName string
param serviceBusQueueName string
param serviceBusTopicName string
param serviceBusSubscriptionName string
param location string = resourceGroup().location
param tags object = {}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
  tags: tags
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: serviceBusQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: serviceBusTopicName
  properties: {
    defaultMessageTimeToLive: 'P7D' // Default time-to-live for messages
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  parent: serviceBusTopic
  name: serviceBusSubscriptionName
  properties: {
    lockDuration: 'PT5M'
    maxDeliveryCount: 10
    defaultMessageTimeToLive: 'P7D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
    autoDeleteOnIdle: 'P30D'
  }
}

output topicName string = serviceBusTopicName
output subscriptionName string = serviceBusSubscriptionName
output namespaceName string = serviceBusNamespaceName
output fullyQualifiedNamespace string = '${serviceBusNamespaceName}.servicebus.windows.net'
